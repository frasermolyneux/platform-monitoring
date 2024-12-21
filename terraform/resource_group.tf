resource "azurerm_resource_group" "rg" {
  name     = "rg-platform-monitoring-${var.environment}-${var.location}-${var.instance}"
  location = var.location

  tags = var.tags
}
