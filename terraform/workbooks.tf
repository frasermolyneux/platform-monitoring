locals {
  workbook_templates = [for f in fileset("workbooks", "*.json") : {
    workbook_name = replace(f, ".json", "")
    data_json = jsondecode(replace(
      file("workbooks/${f}"),
      "__FLEET_WORKSPACE_RESOURCE_ID__",
      var.noncritical_log_analytics.enabled ? azurerm_log_analytics_workspace.noncritical[0].id : azurerm_log_analytics_workspace.law.id
    ))
  } if f != "baremetal-fleet-health.json" || var.noncritical_log_analytics.enabled]
}

resource "random_uuid" "workbook" {
  for_each = { for each in local.workbook_templates : each.workbook_name => each }
}

resource "azurerm_application_insights_workbook" "workbook" {
  for_each = { for each in local.workbook_templates : each.workbook_name => each }

  name = random_uuid.workbook[each.key].result

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location

  display_name = "platform-monitoring-${each.key}-${var.environment}"

  data_json = jsonencode(each.value.data_json)

  tags = var.tags
}
