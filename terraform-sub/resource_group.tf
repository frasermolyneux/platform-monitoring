resource "azurerm_resource_group" "rg" {
  name     = "rg-platform-alerts-${var.environment}-${var.location}"
  location = var.location

  tags = var.tags
}
