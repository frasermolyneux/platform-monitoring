locals {
  action_group_resource_group = "rg-platform-monitoring-${var.environment}-${var.location}"
}

data "azurerm_monitor_action_group" "critical" {
  provider = azurerm.action_group

  name                = "CriticalAlertsAction"
  resource_group_name = local.action_group_resource_group
}

data "azurerm_monitor_action_group" "high" {
  provider = azurerm.action_group

  name                = "HighAlertsAction"
  resource_group_name = local.action_group_resource_group
}

data "azurerm_monitor_action_group" "moderate" {
  provider = azurerm.action_group

  name                = "ModerateAlertsAction"
  resource_group_name = local.action_group_resource_group
}

data "azurerm_monitor_action_group" "low" {
  provider = azurerm.action_group

  name                = "LowAlertsAction"
  resource_group_name = local.action_group_resource_group
}

data "azurerm_monitor_action_group" "informational" {
  provider = azurerm.action_group

  name                = "InformationalAlertsAction"
  resource_group_name = local.action_group_resource_group
}
