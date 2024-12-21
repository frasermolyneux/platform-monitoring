terraform {
  required_version = ">= 1.6.2"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.14.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    resource_group {
      # Resource group is only used by workload, App Insights creates artifacts that need to be deleted
      prevent_deletion_if_contains_resources = false
    }
  }

  storage_use_azuread = true
}

provider "azurerm" {
  alias           = "geolocation"
  subscription_id = var.geolocation_app_insights.subscription_id

  features {}

  storage_use_azuread = true
}

provider "azurerm" {
  alias           = "portal"
  subscription_id = var.portal_app_insights.subscription_id

  features {}

  storage_use_azuread = true
}
