resource "azurerm_monitor_action_group" "critical" {
  name                = "p0-critical-alerts-${var.environment}"
  resource_group_name = local.platform_monitoring_resource_groups[var.locations[0]]
  short_name          = "p0action${var.environment}"

  dynamic "sms_receiver" {
    for_each = var.environment == "prd" ? [1] : []

    content {
      name         = "sms"
      country_code = "44"
      phone_number = azurerm_key_vault_secret.alert_phone.value
    }
  }

  dynamic "email_receiver" {
    for_each = var.environment == "prd" ? [1] : []

    content {
      name          = "email"
      email_address = azurerm_key_vault_secret.alert_email.value
    }
  }

  dynamic "azure_app_push_receiver" {
    for_each = var.environment == "prd" ? [1] : []

    content {
      name          = "push"
      email_address = azurerm_key_vault_secret.alert_email.value
    }
  }
}

resource "azurerm_monitor_action_group" "high" {
  name                = "p1-high-alerts-${var.environment}"
  resource_group_name = local.platform_monitoring_resource_groups[var.locations[0]]
  short_name          = "p1action${var.environment}"

  dynamic "email_receiver" {
    for_each = var.environment == "prd" ? [1] : []

    content {
      name          = "email"
      email_address = azurerm_key_vault_secret.alert_email.value
    }
  }

  dynamic "azure_app_push_receiver" {
    for_each = var.environment == "prd" ? [1] : []

    content {
      name          = "push"
      email_address = azurerm_key_vault_secret.alert_email.value
    }
  }
}

resource "azurerm_monitor_action_group" "moderate" {
  name                = "p2-moderate-alerts-${var.environment}"
  resource_group_name = local.platform_monitoring_resource_groups[var.locations[0]]
  short_name          = "p2action${var.environment}"

  dynamic "email_receiver" {
    for_each = var.environment == "prd" ? [1] : []

    content {
      name          = "email"
      email_address = azurerm_key_vault_secret.alert_email.value
    }
  }
}

resource "azurerm_monitor_action_group" "low" {
  name                = "p3-low-alerts-${var.environment}"
  resource_group_name = local.platform_monitoring_resource_groups[var.locations[0]]
  short_name          = "p3action${var.environment}"
}

resource "azurerm_monitor_action_group" "informational" {
  name                = "p4-informational-alerts-${var.environment}"
  resource_group_name = local.platform_monitoring_resource_groups[var.locations[0]]
  short_name          = "p4action${var.environment}"
}
