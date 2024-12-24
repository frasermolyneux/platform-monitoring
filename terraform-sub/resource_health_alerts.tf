resource "azurerm_monitor_activity_log_alert" "subscription_resource_health_alerts" {
  name = "platform-${var.subscription_name} - ${var.environment} - resource health"

  resource_group_name = azurerm_resource_group.rg.name
  location            = "global"

  scopes      = ["/subscriptions/${var.subscription_id}"]
  description = "Platform resource health alert for ${var.subscription_name} subscription"

  criteria {
    category = "ResourceHealth"

    resource_health {
      previous = ["Available"]
    }
  }

  action {
    action_group_id = var.environment == "prd" ? data.azurerm_monitor_action_group.low.id : data.azurerm_monitor_action_group.informational.id
  }

  tags = var.tags
}
