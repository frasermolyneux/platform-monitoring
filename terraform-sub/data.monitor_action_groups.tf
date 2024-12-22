locals {
  action_group_resource_group = "rg-platform-monitoring-${var.environment}-${var.location}"
}

data "azurerm_monitor_action_group" "critical" {
  provider = azurerm.action_group

  name                = "p0-critical-alerts-${var.environment}"
  resource_group_name = local.action_group_resource_group
}

data "azurerm_monitor_action_group" "high" {
  provider = azurerm.action_group

  name                = "p1-high-alerts-${var.environment}"
  resource_group_name = local.action_group_resource_group
}

data "azurerm_monitor_action_group" "moderate" {
  provider = azurerm.action_group

  name                = "p2-moderate-alerts-${var.environment}"
  resource_group_name = local.action_group_resource_group
}

data "azurerm_monitor_action_group" "low" {
  provider = azurerm.action_group

  name                = "p3-low-alerts-${var.environment}"
  resource_group_name = local.action_group_resource_group
}

data "azurerm_monitor_action_group" "informational" {
  provider = azurerm.action_group

  name                = "p4-informational-alerts-${var.environment}"
  resource_group_name = local.action_group_resource_group
}
