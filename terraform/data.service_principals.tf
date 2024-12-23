data "azuread_service_principal" "azure_monitor_readers" {
  for_each = toset(var.azure_monitor_readers)

  display_name = each.key
}
