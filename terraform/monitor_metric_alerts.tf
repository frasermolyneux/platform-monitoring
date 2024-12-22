resource "azurerm_monitor_metric_alert" "availability" {
  for_each = { for each in var.availability_tests : each.app => each }

  name = "${each.value.workload}-${each.value.environment} - ${each.key} - availability"

  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  scopes              = [local.app_insights_map[each.value.app_insights].id]

  description = "Availability test for ${each.key}"

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "availabilityResults/availabilityPercentage"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 95

    dimension {
      name     = "availabilityResult/name"
      operator = "Include"
      values   = [each.key]
    }
  }

  severity = each.value.severity

  action {
    action_group_id = local.action_group_map[each.value.severity].id
  }

  tags = {
    "Workload"    = each.value.workload
    "Environment" = each.value.environment
  }
}
