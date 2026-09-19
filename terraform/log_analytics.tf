resource "azurerm_log_analytics_workspace" "law" {
  name                = "log-platform-monitoring-${var.environment}-${var.location}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  sku               = "PerGB2018"
  retention_in_days = 30

  tags = var.tags
}

resource "azurerm_resource_group" "cost_optimized_monitoring" {
  count    = var.cost_optimized_log_analytics.enabled ? 1 : 0
  provider = azurerm.cost_optimized

  name     = var.cost_optimized_log_analytics.resource_group_name
  location = var.location

  tags = merge(var.tags, {
    CostProfile = "CreditBacked"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_log_analytics_workspace" "cost_optimized" {
  count    = var.cost_optimized_log_analytics.enabled ? 1 : 0
  provider = azurerm.cost_optimized

  name                = var.cost_optimized_log_analytics.workspace_name
  location            = azurerm_resource_group.cost_optimized_monitoring[0].location
  resource_group_name = azurerm_resource_group.cost_optimized_monitoring[0].name

  sku               = "PerGB2018"
  retention_in_days = 30

  local_authentication_enabled = false

  tags = merge(var.tags, {
    CostProfile = "CreditBacked"
  })

  lifecycle {
    prevent_destroy = true
  }
}
