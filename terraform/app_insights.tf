resource "azurerm_application_insights" "ai" {
  for_each = toset(var.locations)

  name                = "ai-platform-monitoring-${var.environment}-${each.value}"
  location            = azurerm_resource_group.rg[each.value].location
  resource_group_name = azurerm_resource_group.rg[each.value].name
  workspace_id        = "/subscriptions/${var.log_analytics_subscription_id}/resourceGroups/${var.log_analytics_resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/${var.log_analytics_workspace_name}"

  application_type = "web"
}
