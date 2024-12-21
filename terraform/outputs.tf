locals {
  func_apps = [for app in azurerm_linux_function_app.app : {
    name                = app.name
    resource_group_name = app.resource_group_name
    location            = app.location
  }]
}

output "func_apps" {
  value = local.func_apps
}
