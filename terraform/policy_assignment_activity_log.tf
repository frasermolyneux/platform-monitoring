data "azurerm_management_group" "alz" {
  count = var.environment == "prd" ? 1 : 0
  name  = "alz"
}

import {
  for_each = var.environment == "prd" ? toset(["prd"]) : toset([])
  to       = azurerm_management_group_policy_assignment.deploy_az_activity_log[0]
  id       = "/providers/Microsoft.Management/managementGroups/alz/providers/Microsoft.Authorization/policyAssignments/Deploy-AzActivity-Log"
}

resource "azurerm_management_group_policy_assignment" "deploy_az_activity_log" {
  count                = var.environment == "prd" ? 1 : 0
  name                 = "Deploy-AzActivity-Log"
  display_name         = "Deploy Diagnostic Settings for Activity Log to Log Analytics workspace"
  description          = "Ensures that Activity Log Diagnostics settings are set to push logs into Log Analytics workspace."
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2465583e-4e78-4c15-b6be-a36cbc7c8b0f"
  management_group_id  = data.azurerm_management_group.alz[0].id
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

import {
  for_each = var.environment == "prd" ? toset(["prd"]) : toset([])
  to       = azurerm_role_assignment.activity_log_policy_owner[0]
  id       = "/providers/Microsoft.Management/managementGroups/alz/providers/Microsoft.Authorization/roleAssignments/0983ac74-2c4a-56df-9f5b-e22385ccedaf"
}

resource "azurerm_role_assignment" "activity_log_policy_owner" {
  count                = var.environment == "prd" ? 1 : 0
  scope                = data.azurerm_management_group.alz[0].id
  role_definition_name = "Owner"
  principal_id         = azurerm_management_group_policy_assignment.deploy_az_activity_log[0].identity[0].principal_id
}
