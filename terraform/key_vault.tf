resource "azurerm_key_vault" "kv" {
  name                = "kv-${random_id.environment_id.hex}-${var.locations[0]}"
  location            = var.locations[0]
  resource_group_name = local.platform_monitoring_resource_groups[var.locations[0]]
  tenant_id           = data.azurerm_client_config.current.tenant_id

  tags = var.tags

  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  rbac_authorization_enabled = true

  sku_name = "standard"

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }
}
