import copy
import unittest

from verify_status_evidence import notification_request, verify_delivery


TENANT = "11111111-1111-1111-1111-111111111111"
GROUP_ID = "/subscriptions/test/resourceGroups/test/providers/Microsoft.Insights/actionGroups/status-evidence-prd"


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
