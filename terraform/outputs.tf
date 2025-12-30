locals {
  subscriptions = [for sub in var.subscriptions : {
    name            = sub.name
    subscription_id = sub.subscription_id
  }]
}

output "subscriptions" {
  value = local.subscriptions
}

output "log_analytics" {
  value = {
    name                = azurerm_log_analytics_workspace.law.name
    id                  = azurerm_log_analytics_workspace.law.id
    resource_group_name = azurerm_log_analytics_workspace.law.resource_group_name
    location            = azurerm_log_analytics_workspace.law.location
    workspace_id        = azurerm_log_analytics_workspace.law.workspace_id
  }
}
