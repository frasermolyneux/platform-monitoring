locals {
  linux_root_disk_state_kql = <<-KQL
    Perf
    | where TimeGenerated > ago(10m)
    | where ObjectName == "Logical Disk"
    | where InstanceName == "/"
    | where CounterName in ("% Free Space", "Free Megabytes")
    | summarize arg_max(TimeGenerated, CounterValue) by Computer, CounterName
    | summarize
        FreePercent = maxif(CounterValue, CounterName == "% Free Space"),
        FreeMegabytes = maxif(CounterValue, CounterName == "Free Megabytes")
      by Computer
    | where isnotnull(FreePercent) and isnotnull(FreeMegabytes)
  KQL

  database_health_state_kql = <<-KQL
    Syslog
    | where TimeGenerated > ago(15m)
    | where Facility == "local0"
    | where ProcessName == "platform-database-health"
    | extend Server = extract(@"server=([^ ]+)", 1, SyslogMessage),
             Workload = extract(@"workload=([^ ]+)", 1, SyslogMessage),
             Result = extract(@"status=([^ ]+)", 1, SyslogMessage),
             Reason = extract(@"reason=([^ ]+)", 1, SyslogMessage),
             ConnectionPercent = toint(extract(@"connection_percent=([0-9]+)", 1, SyslogMessage)),
             BinlogBytes = tolong(extract(@"binlog_bytes=([0-9]+)", 1, SyslogMessage))
    | summarize arg_max(TimeGenerated, Result, Reason, ConnectionPercent, BinlogBytes, SyslogMessage) by Server, Workload
  KQL
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "linux_disk_space_warning" {
  count    = var.noncritical_log_analytics.enabled ? 1 : 0
  provider = azurerm.noncritical

  name                = "platform-linux-disk-space-warning-${var.environment}"
  resource_group_name = azurerm_resource_group.noncritical_monitoring[0].name
  location            = azurerm_resource_group.noncritical_monitoring[0].location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT10M"
  scopes                  = [azurerm_log_analytics_workspace.noncritical[0].id]
  severity                = 2
  description             = "Alerts when a monitored Linux root filesystem has less than 20 percent free space without crossing the critical threshold."
  enabled                 = true
  auto_mitigation_enabled = true

  criteria {
    query = <<-KQL
      ${local.linux_root_disk_state_kql}
      | where (FreePercent < 20 or FreeMegabytes < 102400)
          and FreePercent >= 10
          and FreeMegabytes >= 51200
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
    action_groups = [azurerm_monitor_action_group.moderate.id]
  }

  tags = merge(var.tags, {
    TelemetryClass = "Noncritical"
  })
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "linux_disk_space_critical" {
  count    = var.noncritical_log_analytics.enabled ? 1 : 0
  provider = azurerm.noncritical

  name                = "platform-linux-disk-space-critical-${var.environment}"
  resource_group_name = azurerm_resource_group.noncritical_monitoring[0].name
  location            = azurerm_resource_group.noncritical_monitoring[0].location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT10M"
  scopes                  = [azurerm_log_analytics_workspace.noncritical[0].id]
  severity                = 1
  description             = "Alerts when a monitored Linux root filesystem has less than 10 percent or 50 GiB free space."
  enabled                 = true
  auto_mitigation_enabled = true

  criteria {
    query = <<-KQL
      ${local.linux_root_disk_state_kql}
      | where FreePercent < 10 or FreeMegabytes < 51200
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

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "database_pressure_warning" {
  count    = var.noncritical_log_analytics.enabled ? 1 : 0
  provider = azurerm.noncritical

  name                = "platform-database-pressure-warning-${var.environment}"
  resource_group_name = azurerm_resource_group.noncritical_monitoring[0].name
  location            = azurerm_resource_group.noncritical_monitoring[0].location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT15M"
  scopes                  = [azurerm_log_analytics_workspace.noncritical[0].id]
  severity                = 2
  description             = "Alerts when a managed database reports warning-level connection or binary-log pressure."
  enabled                 = true
  auto_mitigation_enabled = true

  criteria {
    query = <<-KQL
      ${local.database_health_state_kql}
      | where Result == "warning"
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
    action_groups = [azurerm_monitor_action_group.moderate.id]
  }

  tags = merge(var.tags, {
    TelemetryClass = "Noncritical"
  })
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "database_pressure_critical" {
  count    = var.noncritical_log_analytics.enabled ? 1 : 0
  provider = azurerm.noncritical

  name                = "platform-database-pressure-critical-${var.environment}"
  resource_group_name = azurerm_resource_group.noncritical_monitoring[0].name
  location            = azurerm_resource_group.noncritical_monitoring[0].location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT15M"
  scopes                  = [azurerm_log_analytics_workspace.noncritical[0].id]
  severity                = 1
  description             = "Alerts when a managed database reports critical connection or binary-log pressure."
  enabled                 = true
  auto_mitigation_enabled = true

  criteria {
    query = <<-KQL
      ${local.database_health_state_kql}
      | where Result == "critical"
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
