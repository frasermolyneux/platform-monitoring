variable "environment" {
  default = "dev"
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

variable "tags" {
  default = {}
}
