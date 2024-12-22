resource "azurerm_monitor_action_group" "critical" {
  name                = "CriticalAlertsAction"
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
  name                = "HighAlertsAction"
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
  name                = "ModerateAlertsAction"
  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  short_name          = "p2action"

  email_receiver {
    name          = "email"
    email_address = azurerm_key_vault_secret.alert_email.value
  }
}

resource "azurerm_monitor_action_group" "low" {
  name                = "LowAlertsAction"
  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  short_name          = "p3action"

  email_receiver {
    name          = "email"
    email_address = azurerm_key_vault_secret.alert_email.value
  }
}

resource "azurerm_monitor_action_group" "informational" {
  name                = "InformationalAlertsAction"
  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  short_name          = "p4action"

  email_receiver {
    name          = "email"
    email_address = azurerm_key_vault_secret.alert_email.value
  }
}
