resource "azurerm_monitor_scheduled_query_rules_alert_v2" "backup_failure" {
  count    = var.noncritical_log_analytics.enabled ? 1 : 0
  provider = azurerm.noncritical

  name                = "platform-backup-failure-${var.environment}"
  resource_group_name = azurerm_resource_group.noncritical_monitoring[0].name
  location            = azurerm_resource_group.noncritical_monitoring[0].location

  evaluation_frequency = "PT5M"
  window_duration      = "PT10M"
  scopes               = [azurerm_log_analytics_workspace.noncritical[0].id]
  severity             = 1
  description          = "Alerts when a managed platform backup fails or becomes stale."
  enabled              = true

  criteria {
    query = <<-KQL
      Syslog
      | where Facility == "local0"
      | where ProcessName in ("platform-backup", "platform-backup-health")
      | where SyslogMessage has "status=failed"
    KQL

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.high.id]
  }

  tags = merge(var.tags, {
    TelemetryClass = "Noncritical"
  })
}
