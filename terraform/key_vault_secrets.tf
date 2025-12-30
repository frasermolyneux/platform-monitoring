resource "azurerm_key_vault_secret" "alert_phone" {
  name         = "alert-phone"
  value        = "00000000000"
  key_vault_id = azurerm_key_vault.kv.id

  lifecycle {
    ignore_changes = [value]
  }
}

resource "azurerm_key_vault_secret" "alert_email" {
  name         = "alert-email"
  value        = "noreply@mx-mail.io"
  key_vault_id = azurerm_key_vault.kv.id

  lifecycle {
    ignore_changes = [value]
  }
}
