resource "azurerm_monitor_action_group" "critical" {
  name                = "p0-critical-alerts-${var.environment}"
  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  short_name          = "p0action"

  sms_receiver {
    name         = "sms"
    country_code = "44"
    phone_number = azurerm_key_vault_secret.alert_phone.value
  }

  email_receiver {
    name          = "email"
    email_address = azurerm_key_vault_secret.alert_email.value
  }

  azure_app_push_receiver {
    name          = "push"
    email_address = azurerm_key_vault_secret.alert_email.value
  }
}

resource "azurerm_monitor_action_group" "high" {
  name                = "p1-high-alerts-${var.environment}"
  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  short_name          = "p1action"

  sms_receiver {
    name         = "sms"
    country_code = "44"
    phone_number = azurerm_key_vault_secret.alert_phone.value
  }

  email_receiver {
    name          = "email"
    email_address = azurerm_key_vault_secret.alert_email.value
  }

  azure_app_push_receiver {
    name          = "push"
    email_address = azurerm_key_vault_secret.alert_email.value
  }
}

resource "azurerm_monitor_action_group" "moderate" {
  name                = "p2-moderate-alerts-${var.environment}"
  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  short_name          = "p2action"

  email_receiver {
    name          = "email"
    email_address = azurerm_key_vault_secret.alert_email.value
  }
}

resource "azurerm_monitor_action_group" "low" {
  name                = "p3-low-alerts-${var.environment}"
  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  short_name          = "p3action"

  email_receiver {
    name          = "email"
    email_address = azurerm_key_vault_secret.alert_email.value
  }
}

resource "azurerm_monitor_action_group" "informational" {
  name                = "p4-informational-alerts-${var.environment}"
  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  short_name          = "p4action"

  email_receiver {
    name          = "email"
    email_address = azurerm_key_vault_secret.alert_email.value
  }
}
