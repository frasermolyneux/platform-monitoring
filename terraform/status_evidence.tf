locals {
  status_service_identity = data.terraform_remote_state.platform_workloads.outputs.status_service_identity
}

resource "azurerm_monitor_action_group" "status_evidence" {
  count = var.environment == "prd" ? 1 : 0

  name                = "status-evidence-${var.environment}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "global"
  short_name          = "status${var.environment}"

  webhook_receiver {
    name                    = "private-status-evidence"
    service_uri             = "https://mxstatus.io/api/integrations/azure"
    use_common_alert_schema = true

    aad_auth {
      # application_id in this contract is the registration object ID.
      object_id      = local.status_service_identity.application_id
      identifier_uri = "api://${local.status_service_identity.client_id}"
      tenant_id      = local.status_service_identity.tenant_id
    }
  }

  tags = var.tags
}
