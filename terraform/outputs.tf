locals {
  all_subscriptions    = data.terraform_remote_state.platform_workloads.outputs.subscriptions
  cost_budget_policies = data.terraform_remote_state.platform_workloads.outputs.cost_budget_policies

  subscriptions = [for name, sub in local.all_subscriptions : {
    name                       = sub.name
    subscription_id            = sub.subscription_id
    monthly_budget             = try(local.cost_budget_policies.subscriptions[name].monthly_budget, 0)
    subscription_budget_policy = try(local.cost_budget_policies.subscriptions[name], null)
    workload_budget_policies = {
      for key, policy in try(local.cost_budget_policies.workload_environments, {}) :
      key => policy if lower(policy.subscription_id) == lower(sub.subscription_id)
    }
  } if sub.environment == var.environment]
}

output "subscriptions" {
  value = local.subscriptions

  precondition {
    condition     = try(local.cost_budget_policies.version == 1, false)
    error_message = "Unsupported platform-workloads cost_budget_policies version; expected version 1."
  }
  precondition {
    condition = (
      can(keys(local.cost_budget_policies.subscriptions)) &&
      can(keys(local.cost_budget_policies.workload_environments)) &&
      alltrue([for name, policy in local.cost_budget_policies.subscriptions :
        try(
          policy.monthly_budget >= 0 &&
          lower(policy.subscription_id) == lower(local.all_subscriptions[name].subscription_id),
          false
        )
      ]) &&
      alltrue([for name, sub in local.all_subscriptions :
        can(sub.monthly_budget) ? try(
          sub.monthly_budget == null ||
          tonumber(sub.monthly_budget) <= 0 ||
          can(local.cost_budget_policies.subscriptions[name].monthly_budget),
          false
        ) : true
      ]) &&
      alltrue([for policy in values(try(local.cost_budget_policies.workload_environments, {})) :
        contains([for sub in values(local.all_subscriptions) : lower(sub.subscription_id)], lower(policy.subscription_id))
      ])
    )
    error_message = "Version 1 cost_budget_policies must publish both policy maps, valid policies for enabled subscription budgets, and workload policies scoped to known subscriptions."
  }
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

output "data_collection_rules" {
  description = "Centrally managed data collection rules keyed by platform and telemetry class"
  value = {
    linux_noncritical = var.noncritical_log_analytics.enabled ? {
      id                  = azurerm_monitor_data_collection_rule.linux_noncritical[0].id
      immutable_id        = azurerm_monitor_data_collection_rule.linux_noncritical[0].immutable_id
      name                = azurerm_monitor_data_collection_rule.linux_noncritical[0].name
      resource_group_name = azurerm_monitor_data_collection_rule.linux_noncritical[0].resource_group_name
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

output "status_evidence" {
  description = "Production-only secure webhook group for private status evidence; never a replacement for human alert routing."
  value = var.environment == "prd" ? {
    id                  = azurerm_monitor_action_group.status_evidence[0].id
    name                = azurerm_monitor_action_group.status_evidence[0].name
    resource_group_name = azurerm_monitor_action_group.status_evidence[0].resource_group_name
    subscription_id     = var.subscription_id
  } : null
}
