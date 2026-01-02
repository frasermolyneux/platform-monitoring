# Consuming Platform Monitoring

The platform-monitoring resources are designed to be long-lived and shared across downstream workloads. Both development and production environments are kept online; the development environment is *not* recycled on a schedule, so remote state references remain stable between runs.

## What this project provides

- A central Log Analytics workspace (name, id, resource group, location, workspace id exposed via `log_analytics` output)
- Severity-based Azure Monitor action groups (critical, high, moderate, low, informational) exposed via the `monitor_action_groups` output
- Subscription metadata surfaced through the `subscriptions` output for convenience

## Access and permissions

Platform identities are provisioned via the [platform-workloads](https://github.com/frasermolyneux/platform-workloads) project. Each workload gets a service principal (and optional deploy-script user-assigned identity) with at least `Reader` on its subscription. The critical prerequisite for consumption is **remote state access**: ensure the workload identity has `Storage Blob Data Reader` on the platform-monitoring state storage account so `terraform_remote_state` can read outputs (platform-workloads can grant this via `requires_terraform_state_access`). After state access, layer on the following as needed:

- Publish diagnostics to the shared Log Analytics workspace: add `Log Analytics Contributor` (or `Monitoring Contributor`) on the workspace scope exposed by this repo's outputs.
- Create or update alert rules targeting the shared action groups: add `Monitoring Contributor` scoped to the subscription or resource groups where alerts will live.
- Query workspace data (for log alerts or ad-hoc KQL): add `Log Analytics Reader` if the default `Reader` assignment is insufficient.

Because the platform-monitoring environments stay online (dev is not cycled), these role assignments remain stable for long-running pipelines and state reads.

## Remote state locations

The Terraform backend configurations live in the repository under `terraform/backends/` and are stable for each environment:
- Development: `terraform/backends/dev.backend.hcl`
- Production: `terraform/backends/prd.backend.hcl`

Use the matching backend settings in your consumers so you pull the correct environment state. Because the state containers are stable and not rotated, consumers can safely reference these backends for long-lived pipelines.

## Terraform consumption example (azurerm backend)

The pattern below mirrors the setup used in `platform-sitewatch-func`: environment-specific backend settings are passed in as variables, then the remote state outputs are consumed for alerts and diagnostics.

```hcl
variable "platform_monitoring_state" {
  description = "Backend config for platform-monitoring remote state"
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    key                  = string
    subscription_id      = string
    tenant_id            = string
  })
}

data "terraform_remote_state" "platform_monitoring" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.platform_monitoring_state.resource_group_name
    storage_account_name = var.platform_monitoring_state.storage_account_name
    container_name       = var.platform_monitoring_state.container_name
    key                  = var.platform_monitoring_state.key
    use_oidc             = true
    subscription_id      = var.platform_monitoring_state.subscription_id
    tenant_id            = var.platform_monitoring_state.tenant_id
  }
}

locals {
  log_analytics_workspace_id = data.terraform_remote_state.platform_monitoring.outputs.log_analytics.id
  log_analytics_workspace_rg = data.terraform_remote_state.platform_monitoring.outputs.log_analytics.resource_group_name
  critical_action_group_id   = data.terraform_remote_state.platform_monitoring.outputs.monitor_action_groups["critical"].id
}

resource "azurerm_monitor_metric_alert" "app_health" {
  name                = "app-health"
  resource_group_name = azurerm_resource_group.app.name
  scopes              = [azurerm_function_app.app.id]
  severity            = 2
  description         = "Error rate above threshold"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = local.critical_action_group_id
  }
}

resource "azurerm_monitor_diagnostic_setting" "app_logs" {
  name                       = "send-logs"
  target_resource_id         = azurerm_function_app.app.id
  log_analytics_workspace_id = local.log_analytics_workspace_id

  enabled_log {
    category = "FunctionAppLogs"
  }
}
```

Adjust the backend values to the production settings when wiring production workloads; the file `terraform/backends/prd.backend.hcl` contains the exact configuration.

## Usage notes

- Prefer consuming the remote state rather than duplicating Log Analytics or action groups; this keeps alert routing consistent across workloads.
- Choose the action group severity that matches your alert rules and pass the `id` to `azurerm_monitor_metric_alert` or `azurerm_monitor_activity_log_alert` configurations.
- The central Log Analytics workspace can be used as the target for `azurerm_monitor_diagnostic_setting` or query targets in log-based alerts; use the `workspace_id` output when configuring those resources.
