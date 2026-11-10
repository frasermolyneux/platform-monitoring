variable "environment" {
  default = "dev"
}

variable "location" {
  default = "uksouth"
}

variable "subscription_name" {}

variable "subscription_id" {}

variable "action_group_subscription_id" {}

variable "subscription_budget_policy" {
  description = "Required version 1 subscription policy from platform-workloads."
  type = object({
    monthly_budget      = number
    subscription_id     = string
    scope               = string
    budget_name         = string
    start_date          = string
    actual_thresholds   = set(number)
    forecast_thresholds = set(number)
    contact_emails      = set(string)
  })
  nullable = false
}

variable "workload_budget_policies" {
  description = "Version 1 workload-environment policies for this subscription only. RG scope preserves adopted budgets; subscription scope requires exact ResourceGroupName filters."
  type = map(object({
    monthly_budget       = number
    subscription_id      = string
    scope                = string
    budget_name          = string
    start_date           = string
    actual_thresholds    = set(number)
    forecast_thresholds  = set(number)
    contact_emails       = set(string)
    workload             = string
    environment          = string
    environment_tag      = string
    resource_group_names = set(string)
  }))
  default = {}
}

variable "tags" {
  default = {}
}
