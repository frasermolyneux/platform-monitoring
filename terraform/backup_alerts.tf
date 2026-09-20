locals {
  backup_expected_servers_kql = join(", ", [
    for server in var.backup_expected_servers : "'${replace(server, "'", "''")}'"
  ])
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "backup_failure" {
  count    = var.noncritical_log_analytics.enabled ? 1 : 0
  provider = azurerm.noncritical

  name                = "platform-backup-failure-${var.environment}"
  resource_group_name = azurerm_resource_group.noncritical_monitoring[0].name
  location            = azurerm_resource_group.noncritical_monitoring[0].location

  evaluation_frequency    = "PT5M"
  window_duration         = "P2D"
  scopes                  = [azurerm_log_analytics_workspace.noncritical[0].id]
  severity                = 1
  description             = "Alerts when a managed platform backup fails or becomes stale."
  enabled                 = true
  auto_mitigation_enabled = true

  criteria {
    query = <<-KQL
      let ExpectedServers = datatable(Server:string) [${local.backup_expected_servers_kql}];
      let LatestServerState = Syslog
          | where Facility == "local0"
          | where ProcessName in ("platform-backup", "platform-backup-health")
          | extend Server = extract(@"server=([^ ]+)", 1, SyslogMessage),
                   Workload = extract(@"workload=([^ ]+)", 1, SyslogMessage),
                   BackupKind = extract(@"kind=([^ ]+)", 1, SyslogMessage),
                   Result = extract(@"status=([^ ]+)", 1, SyslogMessage)
          | where ProcessName == "platform-backup-health" or Result == "failed"
          | summarize arg_max(TimeGenerated, Result, ProcessName, Workload, BackupKind, SyslogMessage) by Server;
      ExpectedServers
      | join kind=leftouter LatestServerState on Server
      | where isempty(Result) or Result != "success" or TimeGenerated < ago(30h)
      | extend Result = iff(isempty(Result), "missing", Result)
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
