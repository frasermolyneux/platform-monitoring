variable "environment" {
  default = "dev"
}

variable "workload_name" {
  description = "Name of the workload as defined in platform-workloads state"
  type        = string
  default     = "platform-monitoring"
}

variable "locations" {
  type    = list(string)
  default = ["uksouth"]
}

variable "subscription_id" {}

variable "subscriptions" {
  type = map(object({
    name            = string
    subscription_id = string
  }))
}

variable "platform_workloads_state" {
  description = "Backend config for platform-workloads remote state (used to read workload resource groups/backends)"
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    key                  = string
    subscription_id      = string
    tenant_id            = string
  })
}

variable "tags" {
  default = {}
}
