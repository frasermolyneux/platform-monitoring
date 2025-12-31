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

output "monitor_action_groups" {
  value = {
    critical = {
      id                  = azurerm_monitor_action_group.critical.id
      name                = azurerm_monitor_action_group.critical.name
      resource_group_name = azurerm_monitor_action_group.critical.resource_group_name
      subscription_id     = var.subscription_id
    }
    high = {
      id                  = azurerm_monitor_action_group.high.id
      name                = azurerm_monitor_action_group.high.name
      resource_group_name = azurerm_monitor_action_group.high.resource_group_name
      subscription_id     = var.subscription_id
    }
    moderate = {
      id                  = azurerm_monitor_action_group.moderate.id
      name                = azurerm_monitor_action_group.moderate.name
      resource_group_name = azurerm_monitor_action_group.moderate.resource_group_name
      subscription_id     = var.subscription_id
    }
    low = {
      id                  = azurerm_monitor_action_group.low.id
      name                = azurerm_monitor_action_group.low.name
      resource_group_name = azurerm_monitor_action_group.low.resource_group_name
      subscription_id     = var.subscription_id
    }
    informational = {
      id                  = azurerm_monitor_action_group.informational.id
      name                = azurerm_monitor_action_group.informational.name
      resource_group_name = azurerm_monitor_action_group.informational.resource_group_name
      subscription_id     = var.subscription_id
    }
  }
}
