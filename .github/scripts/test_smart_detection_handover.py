import copy
import os
import subprocess
import sys
import unittest
from unittest import mock

import smart_detection_handover as handover


class HandoverTests(unittest.TestCase):
    def setUp(self):
        environment = mock.patch.dict(os.environ, {"GITHUB_REF": "refs/heads/main"})
        environment.start()
        self.addCleanup(environment.stop)
        self.groups = {
            identifier: {
                "id": identifier, "type": "microsoft.insights/actiongroups", "location": "global",
                "properties": {"enabled": True, "groupShortName": "SmartDetect",
                               "armRoleReceivers": copy.deepcopy(handover.ROLES), "emailReceivers": []},
            }
            for identifier in (handover.OLD, handover.NEW)
        }
        self.rules = {
            identifier: {
                "id": identifier, "type": "Microsoft.AlertsManagement/smartDetectorAlertRules",
                "location": "global", "tags": {"existing": "unchanged"},
                "properties": {
                    "scope": [scope], "detector": {"id": "FailureAnomaliesDetector", "parameters": {}},
                    "state": "Enabled", "severity": "Sev3", "frequency": "PT1M",
                    "description": "retained", "throttling": {"duration": "PT30M"},
                    "actionGroups": {"groupIds": [handover.OLD, "/other/retained-group"],
                                     "customEmailSubject": "retained", "customWebhookPayload": None},
                },
            }
            for identifier, scope in handover.RULES.items()
        }
        self.unknown = set()
        self.live_unknown = set()
        self.live_incomplete = False
        self.writes = []
        self.deletes = []
        self.unexpected_resource = False
        self.fail_write = None
        self.incomplete = False
        api = mock.patch.object(handover, "azure", side_effect=self.azure)
        self.api = api.start()
        self.addCleanup(api.stop)

    def azure(self, method, path, version, body=None):
        if method == "post":
            identifiers = self.unknown | {
                identifier.lower() for identifier, rule in self.rules.items()
                if handover.OLD.lower() in [
                    group.lower() for group in rule["properties"]["actionGroups"]["groupIds"]
                ]
            }
            return {"data": [{"id": identifier} for identifier in identifiers],
                    "count": len(identifiers),
                    "totalRecords": len(identifiers) + int(self.incomplete)}
        if method == "get":
            if "/providers/" in path and path not in self.groups and path not in self.rules:
                if path.endswith("/providers/Microsoft.Insights/actionGroups"):
                    return {"value": copy.deepcopy(list(self.groups.values()))}
                if path.endswith("/smartDetectorAlertRules"):
                    resources = list(self.rules.values()) + [
                        {"id": identifier, "properties": {"actionGroups": {"groupIds": [handover.OLD]}}}
                        for identifier in self.live_unknown
                    ]
                    return {"value": copy.deepcopy(resources),
                            "nextLink": "/more" if self.live_incomplete else None}
                return {"value": []}
            if path.endswith("/resources"):
                resources = [{"id": handover.OLD}] if handover.OLD in self.groups else []
                if self.unexpected_resource:
                    resources.append({"id": "/unexpected/resource"})
                return {"value": resources}
            return copy.deepcopy(self.groups[path] if path in self.groups else self.rules[path])
        if method == "delete" and path == handover.OLD:
            self.deletes.append(path)
            del self.groups[path]
            return None
        if method == "put" and path in self.rules:
            if self.fail_write == path:
                self.fail_write = None
                raise RuntimeError("Simulated partial write failure.")
            self.writes.append(path)
            self.rules[path] = {**self.rules[path], **copy.deepcopy(body)}
            return copy.deepcopy(self.rules[path])
        self.fail("Unexpected Azure operation.")

    def test_only_group_id_changes_and_repeat_is_noop(self):
        expected = {
            identifier: handover.replacement(rule, identifier, handover.RULES[identifier])
            for identifier, rule in self.rules.items()
        }
        handover.main()
        self.assertEqual(len(self.writes), 3)
        for identifier, rule in self.rules.items():
            self.assertEqual({key: rule[key] for key in ("location", "tags", "properties")},
                             expected[identifier])
        handover.main()
        self.assertEqual(len(self.writes), 3)
        self.assertEqual(set(self.groups), {handover.OLD, handover.NEW})

    def test_unknown_reference_or_incomplete_inventory_never_writes(self):
        for attribute, value in (("unknown", {"/unexpected/alert"}), ("incomplete", True)):
            original = getattr(self, attribute)
            with self.subTest(attribute=attribute):
                setattr(self, attribute, value)
                try:
                    with self.assertRaises(ValueError):
                        handover.main()
                    self.assertEqual(self.writes, [])
                finally:
                    setattr(self, attribute, original)

    def test_receiver_or_alert_scope_drift_never_writes(self):
        self.groups[handover.NEW]["properties"]["armRoleReceivers"][0]["useCommonAlertSchema"] = False
        with self.assertRaises(ValueError):
            handover.main()
        self.assertEqual(self.writes, [])
        self.groups[handover.NEW] = copy.deepcopy(self.groups[handover.OLD])
        self.groups[handover.NEW]["id"] = handover.NEW
        self.rules[next(iter(self.rules))]["properties"]["scope"] = ["/wrong/component"]
        with self.assertRaises(ValueError):
            handover.main()
        self.assertEqual(self.writes, [])

    def test_partial_retry_retains_old_group_and_completes_only_remaining_updates(self):
        second = list(self.rules)[1]
        self.fail_write = second
        with self.assertRaises(RuntimeError):
            handover.main()
        self.assertEqual(len(self.writes), 1)
        self.assertIn(handover.OLD, self.groups)
        handover.main()
        self.assertEqual(len(self.writes), 3)

    def test_non_main_never_contacts_azure(self):
        with mock.patch.dict(os.environ, {"GITHUB_REF": "refs/heads/unreviewed"}):
            with self.assertRaises(ValueError):
                handover.main()
        self.api.assert_not_called()

    def test_concurrent_alert_edit_is_not_overwritten(self):
        first = next(iter(self.rules))
        reads = 0

        def changing(method, path, version, body=None):
            nonlocal reads
            if method == "get" and path == first:
                reads += 1
                if reads == 2:
                    self.rules[first]["properties"]["description"] = "concurrent edit"
            return self.azure(method, path, version, body)

        self.api.side_effect = changing
        with self.assertRaises(ValueError):
            handover.main()
        self.assertEqual(self.writes, [])
        self.assertEqual(self.rules[first]["properties"]["description"], "concurrent edit")

    def test_index_lag_keeps_old_group_until_inventory_catches_up(self):
        with mock.patch.object(handover, "references", side_effect=[
            set(identifier.lower() for identifier in self.rules), {"/indexed/old-reference"}, set()
        ]), mock.patch.object(handover.time, "sleep") as sleep:
            handover.main()
        sleep.assert_called_once_with(10)
        self.assertEqual(len(self.writes), 3)
        self.assertIn(handover.OLD, self.groups)

    def test_cleanup_rejects_live_routing_and_then_only_deletes_old_group(self):
        with self.assertRaises(ValueError):
            handover.retire_old_group()
        self.assertEqual(self.deletes, [])
        handover.main()
        handover.retire_old_group()
        handover.retire_old_group()
        self.assertEqual(self.deletes, [handover.OLD])
        self.assertIn(handover.NEW, self.groups)
        self.assertEqual(len(self.rules), 3)

    def test_cleanup_rejects_unknown_references_and_unexpected_resources(self):
        handover.main()
        for attribute, value in (("unknown", {"/unexpected/reference"}), ("unexpected_resource", True)):
            original = getattr(self, attribute)
            with self.subTest(attribute=attribute):
                setattr(self, attribute, value)
                try:
                    with self.assertRaises(ValueError):
                        handover.retire_old_group()
                    self.assertEqual(self.deletes, [])
                finally:
                    setattr(self, attribute, original)

    def test_audit_survives_complete_retirement_but_requires_verified_routes(self):
        handover.audit()
        del self.groups[handover.OLD]
        with self.assertRaises(handover.GuardFailure):
            handover.audit()
        for identifier, rule in self.rules.items():
            self.rules[identifier] = {
                **rule, **handover.replacement(rule, identifier, handover.RULES[identifier])
            }
        handover.audit()
        self.assertEqual(self.writes, [])
        self.assertEqual(self.deletes, [])
        self.unknown = {"/unexpected/reference"}
        with self.assertRaises(handover.GuardFailure):
            handover.audit()

    def test_audit_rejects_incomplete_listing_and_receiver_drift(self):
        with mock.patch.object(handover, "azure", return_value={"value": [], "nextLink": "/more"}):
            with self.assertRaises(handover.GuardFailure):
                handover.audit()
        handover.main()
        del self.groups[handover.OLD]
        self.groups[handover.NEW]["properties"]["armRoleReceivers"][0]["useCommonAlertSchema"] = False
        with self.assertRaises(handover.GuardFailure):
            handover.audit()

    def test_entrypoint_preserves_authored_guard_reason_without_a_traceback(self):
        result = subprocess.run(
            [sys.executable, handover.__file__, "--unsupported"],
            text=True, capture_output=True, check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unsupported operation.", result.stderr)
        self.assertNotIn("Traceback", result.stderr)

    def test_graph_false_negative_cannot_authorize_deletion_of_a_live_reference(self):
        handover.main()
        self.live_unknown = {"/recent/unindexed/alert"}
        with mock.patch.object(handover, "references", return_value=set()):
            with self.assertRaises(handover.GuardFailure):
                handover.retire_old_group()
        self.assertEqual(self.deletes, [])
        self.assertIn(handover.OLD, self.groups)

    def test_incomplete_live_inventory_blocks_handover_before_any_writes(self):
        self.live_incomplete = True
        with self.assertRaises(handover.GuardFailure):
            handover.main()
        self.assertEqual(self.writes, [])
        self.assertEqual(self.deletes, [])

    def test_api_metadata_enrichment_is_not_submitted_or_treated_as_configuration_drift(self):
        third = list(self.rules)[2]
        self.rules[third]["properties"]["state"] = "Disabled"

        def enriching(method, path, version, body=None):
            if method == "put":
                self.assertEqual(set(body["properties"]["detector"]), {"id", "parameters"})
            result = self.azure(method, path, version, body)
            if method == "put":
                self.rules[path]["properties"]["detector"].update({
                    "name": "Failure Anomalies", "description": "service-owned metadata",
                    "parameterDefinitions": [], "supportedCadences": [60],
                    "supportedResourceTypes": ["microsoft.insights/components"],
                })
            return result

        self.api.side_effect = enriching
        handover.main()
        handover.main()
        self.assertEqual(len(self.writes), 3)
        self.assertEqual(self.rules[third]["properties"]["state"], "Disabled")
        self.assertIn(handover.OLD, self.groups)

    def test_writable_detector_parameter_drift_still_fails_verification(self):
        def changing(method, path, version, body=None):
            result = self.azure(method, path, version, body)
            if method == "put":
                self.rules[path]["properties"]["detector"]["parameters"] = {"unexpected": True}
            return result

        self.api.side_effect = changing
        with self.assertRaises(handover.GuardFailure):
            handover.main()
        self.assertEqual(len(self.writes), 1)
        self.assertEqual(self.deletes, [])
        self.assertIn(handover.OLD, self.groups)


if __name__ == "__main__":
    unittest.main()
