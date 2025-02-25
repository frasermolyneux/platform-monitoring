variable "environment" {
  default = "dev"
}

variable "locations" {
  type    = list(string)
  default = ["uksouth", "eastus"]
}

variable "subscription_id" {}

variable "subscriptions" {
  type = map(object({
    name            = string
    subscription_id = string
  }))
}

variable "azure_monitor_readers" {
  type    = list(string)
  default = []
}

variable "geolocation_app_insights" {
  type = object({
    subscription_id     = string
    resource_group_name = string
    name                = string
  })
}

variable "portal_app_insights" {
  type = object({
    subscription_id     = string
    resource_group_name = string
    name                = string
  })
}

variable "availability_tests" {
  type = list(object({
    workload     = string
    environment  = string
    app          = string
    app_insights = string
    uri          = string
    severity     = number
  }))
}

variable "log_analytics_subscription_id" {}
variable "log_analytics_resource_group_name" {}
variable "log_analytics_workspace_name" {}

variable "app_service_plan" {
  type = object({
    sku = string
  })
}

variable "tags" {
  default = {}
}
