resource "azurerm_resource_group" "rg" {
  name     = "rg-service-health-alerts-${var.environment}-${var.location}"
  location = var.location

  tags = var.tags
}
