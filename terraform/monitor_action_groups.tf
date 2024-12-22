resource "azurerm_monitor_action_group" "critical" {
  name                = "CriticalAlertsAction"
  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  short_name          = "p0action"
}

resource "azurerm_monitor_action_group" "high" {
  name                = "HighAlertsAction"
  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  short_name          = "p1action"
}

resource "azurerm_monitor_action_group" "moderate" {
  name                = "ModerateAlertsAction"
  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  short_name          = "p2action"
}

resource "azurerm_monitor_action_group" "low" {
  name                = "LowAlertsAction"
  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  short_name          = "p3action"
}

resource "azurerm_monitor_action_group" "informational" {
  name                = "InformationalAlertsAction"
  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  short_name          = "p4action"
}
