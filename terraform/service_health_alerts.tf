resource "azurerm_monitor_activity_log_alert" "subscription_service_health_alerts_incident" {
  for_each = { for each in var.subscriptions : each.name => each }

  name = "platform-${each.key} - ${var.environment} - service health - incident"

  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  location            = "global"

  scopes      = [data.azurerm_subscription.subscriptions[each.key].id]
  description = "Platform service health alert for ${each.key} subscription"

  criteria {
    category = "ServiceHealth"

    service_health {
      events = ["Incident"]
    }
  }

  tags = {
    Environment = var.environment
    Workload    = each.key
    DeployedBy  = var.tags.DeployedBy
    Git         = var.tags.Git
  }
}

resource "azurerm_monitor_activity_log_alert" "subscription_service_health_alerts_maintenance" {
  for_each = { for each in var.subscriptions : each.name => each }

  name = "platform-${each.key} - ${var.environment} - service health - maintenance"

  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  location            = "global"

  scopes      = [data.azurerm_subscription.subscriptions[each.key].id]
  description = "Platform service health alert for ${each.key} subscription"

  criteria {
    category = "ServiceHealth"

    service_health {
      events = ["Maintenance"]
    }
  }

  tags = {
    Environment = var.environment
    Workload    = each.key
    DeployedBy  = var.tags.DeployedBy
    Git         = var.tags.Git
  }
}

resource "azurerm_monitor_activity_log_alert" "subscription_service_health_alerts_informational" {
  for_each = { for each in var.subscriptions : each.name => each }

  name = "platform-${each.key} - ${var.environment} - service health - informational"

  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  location            = "global"

  scopes      = [data.azurerm_subscription.subscriptions[each.key].id]
  description = "Platform service health alert for ${each.key} subscription"

  criteria {
    category = "ServiceHealth"

    service_health {
      events = ["Informational"]
    }
  }

  tags = {
    Environment = var.environment
    Workload    = each.key
    DeployedBy  = var.tags.DeployedBy
    Git         = var.tags.Git
  }
}

resource "azurerm_monitor_activity_log_alert" "subscription_service_health_alerts_action_required" {
  for_each = { for each in var.subscriptions : each.name => each }

  name = "platform-${each.key} - ${var.environment} - service health - action required"

  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  location            = "global"

  scopes      = [data.azurerm_subscription.subscriptions[each.key].id]
  description = "Platform service health alert for ${each.key} subscription"

  criteria {
    category = "ServiceHealth"

    service_health {
      events = ["ActionRequired"]
    }
  }

  tags = {
    Environment = var.environment
    Workload    = each.key
    DeployedBy  = var.tags.DeployedBy
    Git         = var.tags.Git
  }
}

resource "azurerm_monitor_activity_log_alert" "subscription_service_health_alerts_security" {
  for_each = { for each in var.subscriptions : each.name => each }

  name = "platform-${each.key} - ${var.environment} - service health - security"

  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  location            = "global"

  scopes      = [data.azurerm_subscription.subscriptions[each.key].id]
  description = "Platform service health alert for ${each.key} subscription"

  criteria {
    category = "ServiceHealth"

    service_health {
      events = ["Security"]
    }
  }

  tags = {
    Environment = var.environment
    Workload    = each.key
    DeployedBy  = var.tags.DeployedBy
    Git         = var.tags.Git
  }
}
