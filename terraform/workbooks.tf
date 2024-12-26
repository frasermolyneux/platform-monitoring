locals {
  workbook_templates = [for f in fileset("workbooks", "*.json") : {
    workbook_name = replace(f, ".json", "")
    data_json     = jsondecode(file("workbooks/${f}"))
  }]
}

resource "azurerm_application_insights_workbook" "workbook" {
  for_each = { for each in local.workbook_templates : each.workbook_name => each }

  name = "platform-monitoring-${each.key}-${var.environment}"

  resource_group_name = azurerm_resource_group.rg[var.locations[0]].name
  location            = azurerm_resource_group.rg[var.locations[0]].location

  display_name = "platform-monitoring-${each.key}-${var.environment}"

  data_json = jsonencode(each.value.data_json)

  tags = var.tags
}
