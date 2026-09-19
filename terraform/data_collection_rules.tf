resource "azurerm_monitor_data_collection_rule" "linux_noncritical" {
  count    = var.noncritical_log_analytics.enabled ? 1 : 0
  provider = azurerm.noncritical

  name                = var.noncritical_log_analytics.linux_data_collection_rule_name
  resource_group_name = azurerm_resource_group.noncritical_monitoring[0].name
  location            = azurerm_resource_group.noncritical_monitoring[0].location
  kind                = "Linux"
  description         = "Cost-conscious Linux host telemetry that may be filtered, sampled, or dropped."

  destinations {
    log_analytics {
      name                  = "noncritical-log-analytics"
      workspace_resource_id = azurerm_log_analytics_workspace.noncritical[0].id
    }
  }

  data_flow {
    streams = [
      "Microsoft-Perf",
      "Microsoft-Syslog",
    ]
    destinations = ["noncritical-log-analytics"]
  }

  data_sources {
    performance_counter {
      name                          = "linux-capacity-and-health"
      sampling_frequency_in_seconds = 60
      streams                       = ["Microsoft-Perf"]
      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes Memory",
        "\\Memory\\% Used Memory",
        "\\Logical Disk(*)\\% Free Space",
        "\\Logical Disk(*)\\Free Megabytes",
        "\\Network Interface(*)\\Bytes Total/sec",
        "\\System\\Uptime",
      ]
    }

    syslog {
      name           = "linux-security"
      facility_names = ["auth", "authpriv"]
      log_levels = [
        "Info",
        "Notice",
        "Warning",
        "Error",
        "Critical",
        "Alert",
        "Emergency",
      ]
      streams = ["Microsoft-Syslog"]
    }

    syslog {
      name = "linux-system"
      facility_names = [
        "cron",
        "daemon",
        "kern",
        "syslog",
        "user",
      ]
      log_levels = [
        "Warning",
        "Error",
        "Critical",
        "Alert",
        "Emergency",
      ]
      streams = ["Microsoft-Syslog"]
    }
  }

  tags = merge(var.tags, {
    TelemetryClass = "Noncritical"
  })

  lifecycle {
    prevent_destroy = true
  }
}
