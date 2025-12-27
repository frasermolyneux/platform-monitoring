resource "azurerm_application_insights" "ai" {
  for_each = toset(var.locations)

  name                = "ai-platform-monitoring-${var.environment}-${each.value}"
  location            = azurerm_resource_group.rg[each.value].location
  resource_group_name = azurerm_resource_group.rg[each.value].name
  workspace_id        = azurerm_log_analytics_workspace.law.id

  application_type = "web"

  disable_ip_masking = true
}
