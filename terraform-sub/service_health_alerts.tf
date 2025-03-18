resource "azurerm_monitor_activity_log_alert" "subscription_service_health_alerts_incident" {
  name = "platform-${var.subscription_name} - ${var.environment} - service health - incident"

  resource_group_name = azurerm_resource_group.rg.name
  location            = "global"

  scopes      = ["/subscriptions/${var.subscription_id}"]
  description = "Platform service health alert for ${var.subscription_name} subscription"

  criteria {
    category = "ServiceHealth"

    service_health {
      events = ["Incident"]
    }
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.low.id
  }

  tags = {
    Environment = var.environment
    Workload    = var.subscription_name
    DeployedBy  = var.tags.DeployedBy
    Git         = var.tags.Git
  }
}

resource "azurerm_monitor_activity_log_alert" "subscription_service_health_alerts_maintenance" {
  name = "platform-${var.subscription_name} - ${var.environment} - service health - maintenance"

  resource_group_name = azurerm_resource_group.rg.name
  location            = "global"

  scopes      = ["/subscriptions/${var.subscription_id}"]
  description = "Platform service health alert for ${var.subscription_name} subscription"

  criteria {
    category = "ServiceHealth"

    service_health {
      events = ["Maintenance"]
    }
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.informational.id
  }

  tags = {
    Environment = var.environment
    Workload    = var.subscription_name
    DeployedBy  = var.tags.DeployedBy
    Git         = var.tags.Git
  }
}

resource "azurerm_monitor_activity_log_alert" "subscription_service_health_alerts_informational" {
  name = "platform-${var.subscription_name} - ${var.environment} - service health - informational"

  resource_group_name = azurerm_resource_group.rg.name
  location            = "global"

  scopes      = ["/subscriptions/${var.subscription_id}"]
  description = "Platform service health alert for ${var.subscription_name} subscription"

  criteria {
    category = "ServiceHealth"

    service_health {
      events = ["Informational"]
    }
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.informational.id
  }

  tags = {
    Environment = var.environment
    Workload    = var.subscription_name
    DeployedBy  = var.tags.DeployedBy
    Git         = var.tags.Git
  }
}

resource "azurerm_monitor_activity_log_alert" "subscription_service_health_alerts_action_required" {
  name = "platform-${var.subscription_name} - ${var.environment} - service health - action required"

  resource_group_name = azurerm_resource_group.rg.name
  location            = "global"

  scopes      = ["/subscriptions/${var.subscription_id}"]
  description = "Platform service health alert for ${var.subscription_name} subscription"

  criteria {
    category = "ServiceHealth"

    service_health {
      events = ["ActionRequired"]
    }
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.low.id
  }

  tags = {
    Environment = var.environment
    Workload    = var.subscription_name
    DeployedBy  = var.tags.DeployedBy
    Git         = var.tags.Git
  }
}

resource "azurerm_monitor_activity_log_alert" "subscription_service_health_alerts_security" {
  name = "platform-${var.subscription_name} - ${var.environment} - service health - security"

  resource_group_name = azurerm_resource_group.rg.name
  location            = "global"

  scopes      = ["/subscriptions/${var.subscription_id}"]
  description = "Platform service health alert for ${var.subscription_name} subscription"

  criteria {
    category = "ServiceHealth"

    service_health {
      events = ["Security"]
    }
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.high.id
  }

  tags = {
    Environment = var.environment
    Workload    = var.subscription_name
    DeployedBy  = var.tags.DeployedBy
    Git         = var.tags.Git
  }
}
