import copy
import os
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
        self.writes = []
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
            return copy.deepcopy(self.groups[path] if path in self.groups else self.rules[path])
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


if __name__ == "__main__":
    unittest.main()
