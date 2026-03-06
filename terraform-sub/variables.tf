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
}

variable "tags" {
  default = {}
}
