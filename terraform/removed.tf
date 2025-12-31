# Cleanly drop the previously managed resource groups from state without deleting them.
removed {
  from = azurerm_resource_group.rg

  lifecycle {
    destroy = false
  }
}
