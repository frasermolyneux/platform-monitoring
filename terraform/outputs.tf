locals {
  func_apps = [for app in azurerm_linux_function_app.app : {
    name                = app.name
    resource_group_name = app.resource_group_name
    location            = app.location
  }]

  subscriptions = [for sub in var.var.subscriptions : {
    name            = sub.name
    subscription_id = sub.subscription_id
  }]
}

output "func_apps" {
  value = local.func_apps
}

output "subscriptions" {
  value = local.subscriptions
}
