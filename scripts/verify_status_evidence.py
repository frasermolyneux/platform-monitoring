"""Send one native test only to the dedicated private status secure webhook."""

import json
import os
import subprocess
import time
from urllib.parse import urlsplit
from urllib.request import Request, urlopen
from uuid import UUID


def notification_request(group, group_id, tenant_id):
    properties = group["properties"]
    if (group["id"].lower() != group_id.lower() or group["location"].lower() != "global"
            or properties["enabled"] is not True):
        raise ValueError("The enabled global dedicated status action group is required.")
    if any(value for key, value in properties.items()
           if key.endswith("Receivers") and key != "webhookReceivers"):
        raise ValueError("Refusing to test an action group containing non-webhook receivers.")
    receivers = properties["webhookReceivers"]
    if len(receivers) != 1:
        raise ValueError("Exactly one dedicated secure webhook is required.")
    receiver = receivers[0]
    if (receiver["name"] != "private-status-evidence"
            or receiver["serviceUri"] != "https://mxstatus.io/api/integrations/azure"
            or receiver["useAadAuth"] is not True or receiver["useCommonAlertSchema"] is not True
            or UUID(receiver["tenantId"]) != UUID(tenant_id)):
        raise ValueError("The webhook must retain its exact status URL, tenant and Entra/common-schema settings.")
    UUID(receiver["objectId"])
    if not receiver["identifierUri"].startswith("api://"):
        raise ValueError("The status API identifier must use its application client ID.")
    UUID(receiver["identifierUri"].removeprefix("api://"))
    return {"alertType": "servicehealth", "webhookReceivers": [{
        key: receiver[key] for key in (
            "name", "serviceUri", "useAadAuth", "useCommonAlertSchema",
            "tenantId", "objectId", "identifierUri")
    }]}


def verify_delivery(result):
    actions = result["actionDetails"]
    if result["state"] != "Completed" or len(actions) != 1:
        raise ValueError("The native test did not complete exactly one notification.")
    action = actions[0]
    if (action["Name"] != "private-status-evidence" or action["MechanismType"] != "SecureWebhook"
            or action["Status"] != "Completed" or action["SubState"] != "Default"):
        raise ValueError("The dedicated secure webhook did not report the documented successful delivery result.")
    return {key: action[key] for key in ("Name", "MechanismType", "Status", "SubState", "SendTime")}


def main():
    subscription = str(UUID(os.environ["AZURE_SUBSCRIPTION_ID"]))
    group_id = (f"/subscriptions/{subscription}/resourceGroups/rg-platform-monitoring-prd-uksouth"
                "/providers/Microsoft.Insights/actionGroups/status-evidence-prd")
    base = "https://management.azure.com" + group_id
    version = "?api-version=2023-01-01"
    token = json.loads(subprocess.check_output([
        "az", "account", "get-access-token", "--resource",
        "https://management.azure.com/", "--output", "json"], text=True))["accessToken"]

    def request(url, body=None):
        headers = {"Authorization": "Bearer " + token}
        if body is not None:
            headers["Content-Type"] = "application/json"
        payload = None if body is None else json.dumps(body).encode()
        with urlopen(Request(url, data=payload, headers=headers), timeout=60) as response:
            raw = response.read()
            return response.status, response.headers, json.loads(raw) if raw else None

    _, _, group = request(base + version)
    body = notification_request(group, group_id, os.environ["AZURE_TENANT_ID"])
    code, headers, result = request(base + "/createNotifications" + version, body)
    if code not in (200, 202):
        raise RuntimeError(f"Unexpected native notification response: HTTP {code}.")
    polling = headers.get("Location")
    if polling:
        parsed = urlsplit(polling)
        if (parsed.scheme != "https" or parsed.netloc != "management.azure.com"
                or not parsed.path.lower().startswith(group_id.lower() + "/notificationstatus/")):
            raise ValueError("Refusing an unexpected native notification polling location.")
    deadline = time.monotonic() + 420
    progress = None
    while result is None or result.get("state") != "Completed":
        report = json.dumps({
            "fields": sorted(result or {}),
            "state": (result or {}).get("state"),
            "actions": [{key: action.get(key) for key in (
                "Name", "MechanismType", "Status", "SubState", "SendTime")}
                for action in (result or {}).get("actionDetails", [])],
        }, sort_keys=True)
        if report != progress:
            print("Native notification progress: " + report, flush=True)
            progress = report
        if result is not None and result.get("state") in ("Failed", "Canceled", "Cancelled"):
            raise RuntimeError("The native notification failed: " + report)
        if not polling:
            raise RuntimeError("The native notification is incomplete without a polling location.")
        if time.monotonic() >= deadline:
            raise TimeoutError("The native secure-webhook test did not complete within seven minutes. Last status: " + report)
        time.sleep(10)
        _, _, result = request(polling)
    print(json.dumps(verify_delivery(result)))
    print("Verify the received private evidence and unchanged public incident count separately; no public incident was requested.")


if __name__ == "__main__":
    main()
