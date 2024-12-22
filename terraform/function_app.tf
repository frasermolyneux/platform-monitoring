resource "azurerm_linux_function_app" "app" {
  for_each = toset(var.locations)

  name = "fn-platform-monitoring-func-${var.environment}-${each.value}-${random_id.environment_location_id[each.value].hex}"
  tags = var.tags

  resource_group_name = azurerm_resource_group.rg[each.value].name
  location            = azurerm_resource_group.rg[each.value].location

  service_plan_id = azurerm_service_plan.sp[each.value].id

  storage_account_name       = azurerm_storage_account.function_app_storage[each.value].name
  storage_account_access_key = azurerm_storage_account.function_app_storage[each.value].primary_access_key
  //storage_uses_managed_identity = false

  https_only                    = true
  public_network_access_enabled = false

  functions_extension_version = "~4"

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      use_dotnet_isolated_runtime = true
      dotnet_version              = "9.0"
    }

    application_insights_connection_string = azurerm_application_insights.ai[each.value].connection_string
    application_insights_key               = azurerm_application_insights.ai[each.value].instrumentation_key

    ftps_state          = "Disabled"
    always_on           = false // Not possible with consumption tier
    minimum_tls_version = "1.2"
  }

  app_settings = {
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"

    "portal_appinsights_connection_string"      = data.azurerm_application_insights.portal.connection_string
    "geolocation_appinsights_connection_string" = data.azurerm_application_insights.geolocation.connection_string

    "test_config" = toJson(var.availability_tests)

    // https://learn.microsoft.com/en-us/azure/azure-monitor/profiler/profiler-azure-functions#app-settings-for-enabling-profiler
    "APPINSIGHTS_PROFILERFEATURE_VERSION"  = "1.0.0"
    "DiagnosticServices_EXTENSION_VERSION" = "~3"
  }
}
