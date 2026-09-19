variable "environment" {
  default = "dev"
}

variable "workload_name" {
  description = "Name of the workload as defined in platform-workloads state"
  type        = string
  default     = "platform-monitoring"
}

variable "location" {
  default = "uksouth"
}

variable "subscription_id" {}

variable "noncritical_log_analytics" {
  description = "Additional central Log Analytics workspace for telemetry that can tolerate filtering, sampling, or loss"
  type = object({
    enabled                         = bool
    subscription_id                 = string
    resource_group_name             = string
    workspace_name                  = string
    linux_data_collection_rule_name = string
  })
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
