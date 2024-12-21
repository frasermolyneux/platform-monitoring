resource "azurerm_role_assignment" "app-to-storage" {
  for_each = toset(var.locations)

  scope                = azurerm_storage_account.function_app_storage[each.value].id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_linux_function_app.app[each.value].identity[0].principal_id
}
