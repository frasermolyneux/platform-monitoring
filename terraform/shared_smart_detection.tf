provider "azurerm" {
  alias           = "shared_smart_detection"
  subscription_id = var.environment == "prd" ? "903b6685-c12a-4703-ac54-7ec1ff15ca43" : var.subscription_id
  features {}
  storage_use_azuread = true
}

resource "azurerm_resource_group" "shared_smart_detection" {
  count    = var.environment == "prd" ? 1 : 0
  provider = azurerm.shared_smart_detection

  name     = "rg-platform-monitoring-smart-detection-prd-swedencentral"
  location = "swedencentral"
  tags     = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_monitor_action_group" "shared_smart_detection" {
  count    = var.environment == "prd" ? 1 : 0
  provider = azurerm.shared_smart_detection

  name                = "Application Insights Smart Detection"
  resource_group_name = azurerm_resource_group.shared_smart_detection[0].name
  short_name          = "SmartDetect"
  enabled             = true
  tags                = var.tags

  arm_role_receiver {
    name                    = "Monitoring Contributor"
    role_id                 = "749f88d5-cbae-40b8-bcfc-e573ddc772fa"
    use_common_alert_schema = true
  }
  arm_role_receiver {
    name                    = "Monitoring Reader"
    role_id                 = "43d0d8ad-25c7-4714-9337-8ba259a9fe05"
    use_common_alert_schema = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
