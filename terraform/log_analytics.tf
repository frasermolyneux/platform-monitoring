resource "azurerm_log_analytics_workspace" "law" {
  name                = "log-platform-monitoring-${var.environment}-${var.locations[0]}"
  location            = var.locations[0]
  resource_group_name = local.platform_monitoring_resource_groups[var.locations[0]]

  sku               = "PerGB2018"
  retention_in_days = 30

  tags = var.tags
}
