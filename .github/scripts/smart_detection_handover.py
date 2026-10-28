"""Rebind three existing alerts without changing their definitions or recipients."""

import copy
import json
import os
import subprocess
import sys
import time
from urllib.parse import quote


SUBSCRIPTION = "903b6685-c12a-4703-ac54-7ec1ff15ca43"
BASE = f"/subscriptions/{SUBSCRIPTION}/resourceGroups/"
OLD = BASE + ("rg-travel-itinerary-prd-swedencentral/providers/"
              "microsoft.insights/actiongroups/Application Insights Smart Detection")
NEW = BASE + ("rg-platform-monitoring-smart-detection-prd-swedencentral/providers/"
              "microsoft.insights/actiongroups/Application Insights Smart Detection")
ROLES = [
    {"name": "Monitoring Contributor", "roleId": "749f88d5-cbae-40b8-bcfc-e573ddc772fa",
     "useCommonAlertSchema": True},
    {"name": "Monitoring Reader", "roleId": "43d0d8ad-25c7-4714-9337-8ba259a9fe05",
     "useCommonAlertSchema": True},
]
RULES = {
    BASE + f"rg-{name}-prd-{region}/providers/Microsoft.AlertsManagement/"
    f"smartDetectorAlertRules/Failure Anomalies - ai-{name}-prd-{region}":
    BASE + f"rg-{name}-prd-{region}/providers/Microsoft.Insights/components/ai-{name}-prd-{region}"
    for name, region in (
        ("craftpledge", "swedencentral"), ("geo-location", "swedencentral"),
        ("platform-notifications", "uksouth"),
    )
}


class GuardFailure(ValueError):
    """An authored, non-sensitive prerequisite message that may be logged."""


def azure(method, path, version, body=None):
    arguments = [
        "az", "rest", "--method", method,
        "--url", "https://management.azure.com" + quote(path, safe="/") + "?api-version=" + version,
        "--only-show-errors", "--output", "json",
    ]
    if body is not None:
        arguments += ["--body", json.dumps(body)]
    result = subprocess.run(arguments, text=True, capture_output=True, check=False)
    if result.returncode:
        raise RuntimeError("Azure operation failed; diagnostic output withheld.")
    return json.loads(result.stdout) if result.stdout.strip() else None


def references():
    response = azure("post", "/providers/Microsoft.ResourceGraph/resources", "2022-10-01", {
        "subscriptions": [SUBSCRIPTION],
        "query": (
            "Resources | where type !~ 'microsoft.insights/actiongroups' "
            f"| where tolower(tostring(properties)) contains '{OLD.lower()}' | project id"
        ),
        "options": {"resultFormat": "objectArray", "$top": 1000},
    })
    rows = response["data"]
    if (response.get("$skipToken") or response["totalRecords"] != len(rows)
            or response["count"] != len(rows)):
        raise GuardFailure("Reference inventory is incomplete.")
    return {row["id"].lower() for row in rows}


def validate_group(group, identifier):
    properties = group["properties"]
    if (group["id"].lower() != identifier.lower()
            or group["type"].lower() != "microsoft.insights/actiongroups"
            or group["location"].lower() != "global"
            or properties.get("enabled") is not True
            or properties.get("groupShortName") != "SmartDetect"
            or sorted(properties.get("armRoleReceivers", []), key=lambda entry: entry["roleId"])
            != sorted(ROLES, key=lambda entry: entry["roleId"])
            or any(value for key, value in properties.items()
                   if key.endswith("Receivers") and key != "armRoleReceivers")):
        raise GuardFailure("Notification configuration differs from the reviewed two-role contract.")


def replacement(rule, identifier, scope):
    properties = rule["properties"]
    if (rule["id"].lower() != identifier.lower()
            or rule["type"].lower() != "microsoft.alertsmanagement/smartdetectoralertrules"
            or [value.lower() for value in properties.get("scope", [])] != [scope.lower()]
            or properties.get("detector", {}).get("id") != "FailureAnomaliesDetector"):
        raise GuardFailure("Alert identity or instrumentation scope differs from the reviewed contract.")
    body = {"location": rule["location"], "tags": rule.get("tags") or {},
            "properties": copy.deepcopy(properties)}
    groups = body["properties"]["actionGroups"]["groupIds"]
    if sum(value.lower() in (OLD.lower(), NEW.lower()) for value in groups) != 1:
        raise GuardFailure("Alert notification routing differs from the reviewed handover.")
    body["properties"]["actionGroups"]["groupIds"] = [
        NEW if value.lower() == OLD.lower() else value for value in groups
    ]
    return body


def verify_new_routes():
    validate_group(azure("get", NEW, "2023-01-01"), NEW)
    for identifier, scope in RULES.items():
        rule = azure("get", identifier, "2021-04-01")
        body = {"location": rule["location"], "tags": rule.get("tags") or {},
                "properties": rule["properties"]}
        if replacement(rule, identifier, scope) != body:
            raise GuardFailure("A surviving alert still depends on the old group.")


def audit():
    groups = azure("get", f"/subscriptions/{SUBSCRIPTION}/providers/Microsoft.Insights/actionGroups",
                   "2023-01-01")
    if groups.get("nextLink"):
        raise GuardFailure("Action group inventory is incomplete.")
    old = [group for group in groups["value"] if group["id"].lower() == OLD.lower()]
    if old:
        validate_group(old[0], OLD)
        print("Verified original two-role notification configuration; references:", len(references()))
    else:
        verify_new_routes()
        if references():
            raise GuardFailure("The retired group is absent but references still remain.")
        print("Verified retired group absent, replacement recipients and all three surviving routes.")


def main():
    if os.environ.get("GITHUB_REF") != "refs/heads/main":
        raise GuardFailure("Handover is allowed only from reviewed main.")
    validate_group(azure("get", OLD, "2023-01-01"), OLD)
    validate_group(azure("get", NEW, "2023-01-01"), NEW)
    allowed = {identifier.lower() for identifier in RULES}
    if references() - allowed:
        raise GuardFailure("Unknown or not-yet-retired alerts still depend on the old action group.")
    planned = []
    for identifier, scope in RULES.items():
        before = azure("get", identifier, "2021-04-01")
        planned.append((identifier, scope, before, replacement(before, identifier, scope)))
    for identifier, scope, before, desired in planned:
        current = azure("get", identifier, "2021-04-01")
        if current != before:
            raise GuardFailure("Alert changed during preflight; stop rather than overwrite it.")
        current_body = {"location": current["location"], "tags": current.get("tags") or {},
                        "properties": current["properties"]}
        if current_body != desired:
            azure("put", identifier, "2021-04-01", desired)
        after = azure("get", identifier, "2021-04-01")
        after_body = {"location": after["location"], "tags": after.get("tags") or {},
                      "properties": after["properties"]}
        if after_body != desired or replacement(after, identifier, scope) != desired:
            raise GuardFailure("Alert configuration did not verify unchanged apart from its group ID.")
    for attempt in range(19):
        if not references():
            print("Verified three unchanged alert definitions and notification roles; no old references remain.")
            print("The old action group was retained for separately reviewed Travel cleanup.")
            return
        if attempt < 18:
            time.sleep(10)
    raise GuardFailure("Reference index has not cleared; keep the old group and retry safely.")


def retire_old_group():
    if os.environ.get("GITHUB_REF") != "refs/heads/main":
        raise GuardFailure("Cleanup is allowed only from reviewed main.")
    verify_new_routes()
    if references():
        raise GuardFailure("The complete subscription inventory still references the old group.")
    path = BASE + "rg-travel-itinerary-prd-swedencentral/resources"
    inventory = azure("get", path, "2021-04-01")
    resources = inventory["value"]
    if inventory.get("nextLink") or any(resource["id"].lower() != OLD.lower() for resource in resources):
        raise GuardFailure("Travel inventory contains unexpected resources; stop for review.")
    if resources:
        validate_group(azure("get", OLD, "2023-01-01"), OLD)
        if references():
            raise GuardFailure("Old group references appeared during cleanup preflight.")
        azure("delete", OLD, "2023-01-01")
    for attempt in range(19):
        inventory = azure("get", path, "2021-04-01")
        if not inventory.get("nextLink") and not inventory["value"]:
            print("Retired only the unreferenced old group; Travel resource group is empty.")
            return
        if attempt < 18:
            time.sleep(10)
    raise GuardFailure("Travel inventory is not empty; do not decommission its catalog.")


if __name__ == "__main__":
    try:
        if sys.argv[1:] == ["--retire-old-group"]:
            retire_old_group()
        elif not sys.argv[1:]:
            main()
        else:
            raise GuardFailure("Unsupported operation.")
    except GuardFailure as error:
        raise SystemExit(str(error)) from None
    except (ValueError, RuntimeError, KeyError, TypeError):
        raise SystemExit("Notification handover stopped; preserve the old group and review before retrying.") from None
