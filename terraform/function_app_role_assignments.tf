resource "azurerm_role_assignment" "app_to_keyvault" {
  for_each = toset(var.locations)

  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.app[each.value].identity[0].principal_id
}
