locals {
  status_evidence_enabled = var.environment == "prd"
  status_evidence_scope   = "/subscriptions/${var.subscription_id}"
  status_evidence_tags = {
    Environment = var.environment
    Workload    = var.subscription_name
    DeployedBy  = var.tags.DeployedBy
    Git         = var.tags.Git
  }
}

data "azurerm_monitor_action_group" "status_evidence" {
  count    = local.status_evidence_enabled ? 1 : 0
  provider = azurerm.action_group

  name                = "status-evidence-${var.environment}"
  resource_group_name = local.action_group_resource_group
}

resource "azurerm_monitor_activity_log_alert" "status_service_health" {
  count = local.status_evidence_enabled ? 1 : 0

  name                = "status-service-health-${var.subscription_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "global"
  scopes              = [local.status_evidence_scope]
  description         = "Private status evidence for all Service Health events, services and locations."

  criteria {
    category = "ServiceHealth"
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.status_evidence[0].id
  }

  tags = local.status_evidence_tags
}

resource "azurerm_monitor_activity_log_alert" "status_resource_health" {
  count = local.status_evidence_enabled ? 1 : 0

  name                = "status-resource-health-${var.subscription_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "global"
  scopes              = [local.status_evidence_scope]
  description         = "Private status evidence for Resource Health transitions, including recovery."

  criteria {
    category = "ResourceHealth"
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.status_evidence[0].id
  }

  tags = local.status_evidence_tags
}

resource "azurerm_monitor_alert_processing_rule_action_group" "status_metric_log" {
  count = local.status_evidence_enabled ? 1 : 0

  name                 = "status-metric-log-${var.subscription_name}"
  resource_group_name  = azurerm_resource_group.rg.name
  scopes               = [local.status_evidence_scope]
  add_action_group_ids = [data.azurerm_monitor_action_group.status_evidence[0].id]
  description          = "Add private status evidence delivery without replacing existing human notifications."
  enabled              = true

  condition {
    signal_type {
      operator = "Equals"
      values   = ["Metric", "Log"]
    }
    monitor_condition {
      operator = "Equals"
      values   = ["Fired", "Resolved"]
    }
  }

  tags = local.status_evidence_tags
}
