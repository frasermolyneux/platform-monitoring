resource "azurerm_service_plan" "sp" {
  for_each = toset(var.locations)

  name                = "asp-plaform-monitoring-func-${var.environment}-${each.value}"
  location            = azurerm_resource_group.rg[each.value].location
  resource_group_name = azurerm_resource_group.rg[each.value].name

  os_type  = "Linux"
  sku_name = var.app_service_plan.sku
}
