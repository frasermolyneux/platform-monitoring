data "azurerm_management_group" "alz" {
  name = "alz"
}

import {
  to = azurerm_management_group_policy_assignment.deploy_az_activity_log
  id = "/providers/Microsoft.Management/managementGroups/alz/providers/Microsoft.Authorization/policyAssignments/Deploy-AzActivity-Log"
}

resource "azurerm_management_group_policy_assignment" "deploy_az_activity_log" {
  name                 = "Deploy-AzActivity-Log"
  display_name         = "Deploy Diagnostic Settings for Activity Log to Log Analytics workspace"
  description          = "Ensures that Activity Log Diagnostics settings are set to push logs into Log Analytics workspace."
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2465583e-4e78-4c15-b6be-a36cbc7c8b0f"
  management_group_id  = data.azurerm_management_group.alz.id
  enforce              = true

  identity {
    type = "SystemAssigned"
  }

  location = var.location

  parameters = jsonencode({
    effect = {
      value = "DeployIfNotExists"
    }
    logAnalytics = {
      value = azurerm_log_analytics_workspace.law.id
    }
  })
}

resource "azurerm_role_assignment" "activity_log_policy_owner" {
  scope                = data.azurerm_management_group.alz.id
  role_definition_name = "Owner"
  principal_id         = azurerm_management_group_policy_assignment.deploy_az_activity_log.identity[0].principal_id
}
