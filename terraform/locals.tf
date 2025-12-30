locals {
  action_group_map = {
    0 = azurerm_monitor_action_group.critical
    1 = azurerm_monitor_action_group.high
    2 = azurerm_monitor_action_group.moderate
    3 = azurerm_monitor_action_group.low
    4 = azurerm_monitor_action_group.informational
  }
}
