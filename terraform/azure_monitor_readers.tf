resource "azurerm_role_assignment" "monitoring_readers" {
  for_each = toset(var.azure_monitor_readers)

  scope                = azurerm_resource_group.rg[var.locations[0]].id
  role_definition_name = "Monitoring Reader"
  principal_id         = data.azuread_service_principal.azure_monitor_readers[each.key].object_id
}
