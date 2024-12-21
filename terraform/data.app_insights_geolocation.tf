
data "azurerm_application_insights" "geolocation" {
  provider = azurerm.geolocation

  name                = var.geolocation_app_insights.name
  resource_group_name = var.geolocation_app_insights.resource_group_name
}
