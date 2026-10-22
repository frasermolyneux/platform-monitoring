import copy
import io
import json
import unittest
from contextlib import redirect_stdout
from unittest.mock import MagicMock, patch

from verify_status_evidence import main, notification_request, verify_delivery


TENANT = "11111111-1111-1111-1111-111111111111"
SUBSCRIPTION = "55555555-5555-5555-5555-555555555555"
GROUP_ID = (f"/subscriptions/{SUBSCRIPTION}/resourceGroups/rg-platform-monitoring-prd-uksouth"
            "/providers/Microsoft.Insights/actionGroups/status-evidence-prd")


def dedicated_group():
    return {
        "id": GROUP_ID, "location": "global",
        "properties": {"enabled": True, "emailReceivers": [], "webhookReceivers": [{
            "name": "private-status-evidence", "serviceUri": "https://mxstatus.io/api/integrations/azure",
            "useAadAuth": True, "useCommonAlertSchema": True, "tenantId": TENANT,
            "objectId": "22222222-2222-2222-2222-222222222222",
            "identifierUri": "api://33333333-3333-3333-3333-333333333333",
        }]},
    }


class NativeDeliveryTests(unittest.TestCase):
    def test_timeout_reports_response_shape_without_receiver_configuration(self):
        group_response = MagicMock()
        group_response.__enter__.return_value = group_response
        group_response.status = 200
        group_response.headers = {}
        group_response.read.return_value = json.dumps(dedicated_group()).encode()
        acknowledgement = MagicMock()
        acknowledgement.__enter__.return_value = acknowledgement
        acknowledgement.status = 202
        acknowledgement.headers = {"Location":
            "https://management.azure.com" + GROUP_ID + "/notificationStatus/test?api-version=2023-01-01"}
        acknowledgement.read.return_value = b'{"context":{"private":"must-not-log"}}'
        output = io.StringIO()
        with (patch.dict("os.environ", {"AZURE_SUBSCRIPTION_ID": SUBSCRIPTION, "AZURE_TENANT_ID": TENANT}),
              patch("verify_status_evidence.subprocess.check_output", return_value='{"accessToken":"test-token"}'),
              patch("verify_status_evidence.time.monotonic", side_effect=[0, 421]),
              patch("verify_status_evidence.urlopen", side_effect=[group_response, acknowledgement]),
              redirect_stdout(output)):
            with self.assertRaisesRegex(TimeoutError, '"fields": \\["context"\\]'):
                main()
        self.assertNotIn("must-not-log", output.getvalue())
        self.assertNotIn("test-token", output.getvalue())
        self.assertNotIn("identifierUri", output.getvalue())

    def test_sends_only_the_existing_dedicated_secure_webhook(self):
        group = dedicated_group()
        request = notification_request(group, GROUP_ID, TENANT)
        self.assertEqual(request, {
            "alertType": "servicehealth",
            "webhookReceivers": group["properties"]["webhookReceivers"],
        })

    def test_refuses_human_receivers_and_changed_security_boundary(self):
        for key, value in (("serviceUri", "https://example.com/"), ("useAadAuth", False),
                           ("useCommonAlertSchema", False),
                           ("tenantId", "44444444-4444-4444-4444-444444444444")):
            with self.subTest(key=key):
                group = dedicated_group()
                group["properties"]["webhookReceivers"][0][key] = value
                with self.assertRaises(ValueError):
                    notification_request(group, GROUP_ID, TENANT)
        for channel in ("emailReceivers", "smsReceivers", "futureReceivers"):
            with self.subTest(channel=channel):
                group = dedicated_group()
                group["properties"][channel] = [{"name": "not-approved"}]
                with self.assertRaises(ValueError):
                    notification_request(group, GROUP_ID, TENANT)

    def test_overall_completion_does_not_mask_a_failed_or_wrong_receiver(self):
        result = {"state": "Completed", "actionDetails": [{
            "Name": "private-status-evidence", "MechanismType": "SecureWebhook",
            "Status": "Completed", "SubState": "Default", "SendTime": "test-time",
        }]}
        self.assertEqual(verify_delivery(result)["MechanismType"], "SecureWebhook")
        for key, value in (("Status", "Failed"), ("MechanismType", "Email"),
                           ("Name", "another-webhook"), ("SubState", "Failed")):
            with self.subTest(key=key):
                changed = copy.deepcopy(result)
                changed["actionDetails"][0][key] = value
                with self.assertRaises(ValueError):
                    verify_delivery(changed)

    def test_polls_context_only_acknowledgement_until_individual_delivery_completes(self):
        polling = "https://management.azure.com" + GROUP_ID + "/notificationStatus/test?api-version=2023-01-01"
        completed = {"state": "Completed", "actionDetails": [{
            "Name": "private-status-evidence", "MechanismType": "SecureWebhook",
            "Status": "Completed", "SubState": "Default", "SendTime": "test-time",
        }]}

        def response(status, body, headers=None):
            result = MagicMock()
            result.__enter__.return_value = result
            result.status = status
            result.headers = headers or {}
            result.read.return_value = json.dumps(body).encode()
            return result

        responses = [
            response(200, dedicated_group()),
            response(202, {"context": {"notificationSource": "Microsoft.Insights/TestNotification"}},
                     {"Location": polling}),
            response(200, completed),
        ]
        with (patch.dict("os.environ", {"AZURE_SUBSCRIPTION_ID": SUBSCRIPTION, "AZURE_TENANT_ID": TENANT}),
              patch("verify_status_evidence.subprocess.check_output", return_value='{"accessToken":"test-token"}'),
              patch("verify_status_evidence.time.sleep"),
              patch("verify_status_evidence.urlopen", side_effect=responses) as requests,
              redirect_stdout(io.StringIO())):
            main()
        self.assertEqual(requests.call_count, 3)
        self.assertEqual(requests.call_args.args[0].full_url, polling)
