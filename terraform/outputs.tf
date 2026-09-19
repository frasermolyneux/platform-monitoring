locals {
  all_subscriptions = data.terraform_remote_state.platform_workloads.outputs.subscriptions

  subscriptions = [for name, sub in local.all_subscriptions : {
    name            = sub.name
    subscription_id = sub.subscription_id
    monthly_budget  = try(sub.monthly_budget, 0)
  } if sub.environment == var.environment]
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

output "log_analytics_workspaces" {
  description = "Central Log Analytics workspaces keyed by intended cost and placement profile"
  value = {
    primary = {
      name                = azurerm_log_analytics_workspace.law.name
      id                  = azurerm_log_analytics_workspace.law.id
      resource_group_name = azurerm_log_analytics_workspace.law.resource_group_name
      location            = azurerm_log_analytics_workspace.law.location
      workspace_id        = azurerm_log_analytics_workspace.law.workspace_id
      subscription_id     = var.subscription_id
    }
    noncritical = var.noncritical_log_analytics.enabled ? {
      name                = azurerm_log_analytics_workspace.noncritical[0].name
      id                  = azurerm_log_analytics_workspace.noncritical[0].id
      resource_group_name = azurerm_log_analytics_workspace.noncritical[0].resource_group_name
      location            = azurerm_log_analytics_workspace.noncritical[0].location
      workspace_id        = azurerm_log_analytics_workspace.noncritical[0].workspace_id
      subscription_id     = var.noncritical_log_analytics.subscription_id
    } : null
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
