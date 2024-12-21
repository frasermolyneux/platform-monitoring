resource "azurerm_resource_group" "rg" {
  for_each = toset(var.locations)

  name     = "rg-platform-monitoring-${var.environment}-${each.value}"
  location = each.value

  tags = var.tags
}
