resource "azurerm_monitor_activity_log_alert" "subscription_service_health_alerts" {
  for_each = { for each in var.subscriptions : each.name => each }

  name = "platform-${each.key} - ${var.environment} - servicehealth"

  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  location            = var.locations[0]

  scopes      = [data.azurerm_subscription.subscriptions[each.key].id]
  description = "Platform service health alert for ${each.key} subscription"

  criteria {
    category = "ServiceHealth"
  }

  tags = {
    Environment = var.environment
    Workload    = each.key
    DeployedBy  = var.tags.DeployedBy
    Git         = var.tags.Git
  }
}
