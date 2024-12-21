resource "azurerm_monitor_activity_log_alert" "subscription_service_health_alerts" {
  for_each = { for each in var.subscriptions : each.name => each }

  name = "platform-${each.key} - service health"

  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  location            = var.locations[0]

  scopes      = each.value.subscription_id
  description = "Platform service health alert for ${each.key} subscription"

  criteria {
    category = "ServiceHealth"
  }

  tags = {
    Environment = var.environment
    Workload    = each.key
  }
}
