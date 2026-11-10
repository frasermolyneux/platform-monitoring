variable "environment" {
  default = "dev"
}

variable "location" {
  default = "uksouth"
}

variable "subscription_name" {}

variable "subscription_id" {}

variable "action_group_subscription_id" {}

variable "monthly_budget" {
  description = "Monthly budget amount for this subscription. Set to 0 to skip budget creation."
  type        = number
  default     = 0

  validation {
    condition     = var.monthly_budget >= 0
    error_message = "Monthly budget must be nonnegative."
  }
}

variable "subscription_budget_policy" {
  description = "Version 1 subscription policy from platform-workloads; null preserves the legacy monthly_budget input."
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
  default = null
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

variable "legacy_budget_adoption_complete" {
  description = "Operator gate: true only after the documented source ownership releases and central RG budget imports."
  type        = bool
  default     = false
}

variable "tags" {
  default = {}
}
