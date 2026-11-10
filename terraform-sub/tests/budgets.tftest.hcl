mock_provider "azurerm" {}
mock_provider "azurerm" {
  alias = "action_group"
  mock_data "azurerm_monitor_action_group" {
    defaults = {
      id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-monitoring/providers/Microsoft.Insights/actionGroups/test"
    }
  }
}

variables {
  environment                  = "dev"
  subscription_name            = "sub-example"
  subscription_id              = "11111111-1111-1111-1111-111111111111"
  action_group_subscription_id = "11111111-1111-1111-1111-111111111111"
  tags = {
    DeployedBy = "Terraform"
    Git        = "https://github.com/example/example"
  }
}

run "legacy_subscription" {
  command = plan
  variables {
    monthly_budget = 150
  }
  assert {
    condition     = azurerm_consumption_budget_subscription.subscription[0].name == "budget-sub-example"
    error_message = "Existing subscription name/address must be preserved."
  }
  assert {
    condition = (
      azurerm_consumption_budget_subscription.subscription[0].amount == 150 &&
      azurerm_consumption_budget_subscription.subscription[0].time_period[0].start_date == "2026-04-01T00:00:00Z" &&
      length(azurerm_consumption_budget_subscription.subscription[0].notification) == 2 &&
      alltrue([for n in azurerm_consumption_budget_subscription.subscription[0].notification :
        contains(n.contact_emails, "frasermolyneux@mx-mail.io") &&
        (n.threshold_type == "Actual" ? n.threshold == 95 : n.threshold == 110)
      ])
    )
    error_message = "Legacy input must receive direct email, actual 95 and forecast 110 defaults without changing identity."
  }
}

run "disabled_legacy_budget" {
  command = plan
  assert {
    condition     = length(azurerm_consumption_budget_subscription.subscription) == 0
    error_message = "Zero legacy monthly budget must remain disabled."
  }
}

run "version_one_policies" {
  command = plan
  variables {
    legacy_budget_adoption_complete = true
    monthly_budget                  = 999
    subscription_budget_policy = {
      monthly_budget      = 200
      subscription_id     = "11111111-1111-1111-1111-111111111111"
      scope               = "/subscriptions/11111111-1111-1111-1111-111111111111"
      budget_name         = "budget-sub-example"
      start_date          = "2026-04-01T00:00:00Z"
      actual_thresholds   = [25, 75]
      forecast_thresholds = [90]
      contact_emails      = ["budget@example.com"]
    }
    workload_budget_policies = {
      "example-Production" = {
        monthly_budget       = 30
        subscription_id      = "11111111-1111-1111-1111-111111111111"
        scope                = "/subscriptions/11111111-1111-1111-1111-111111111111"
        budget_name          = "example-prd-monthly"
        start_date           = "2026-11-01T00:00:00Z"
        actual_thresholds    = [95]
        forecast_thresholds  = [110]
        contact_emails       = ["budget@example.com"]
        workload             = "example"
        environment          = "Production"
        environment_tag      = "prd"
        resource_group_names = ["rg-example-prd-uksouth", "rg-example-prd-ukwest"]
        rationale            = null
      }
      "platform-radar-Production" = {
        monthly_budget       = 10
        subscription_id      = "11111111-1111-1111-1111-111111111111"
        scope                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-platform-radar-prd-uksouth"
        budget_name          = "radar-monthly"
        start_date           = "2026-10-01T00:00:00Z"
        actual_thresholds    = [95]
        forecast_thresholds  = [110]
        contact_emails       = ["budget@example.com"]
        workload             = "platform-radar"
        environment          = "Production"
        environment_tag      = "prd"
        resource_group_names = ["rg-platform-radar-prd-uksouth"]
      }
      "platform-developer-portal-Production" = {
        monthly_budget       = 10
        subscription_id      = "11111111-1111-1111-1111-111111111111"
        scope                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-platform-developer-portal-prd-uksouth"
        budget_name          = "idp-monthly-notification"
        start_date           = "2026-10-01T00:00:00Z"
        actual_thresholds    = [95]
        forecast_thresholds  = [110]
        contact_emails       = ["budget@example.com"]
        workload             = "platform-developer-portal"
        environment          = "Production"
        environment_tag      = "prd"
        resource_group_names = ["rg-platform-developer-portal-prd-uksouth"]
      }
    }
  }
  assert {
    condition = alltrue([for b in concat(
      values(azurerm_consumption_budget_subscription.workload),
      values(azurerm_consumption_budget_resource_group.workload)
      ) :
      length(b.notification) == 2 &&
      alltrue([for n in b.notification :
        n.enabled && n.operator == "GreaterThanOrEqualTo" &&
        contains(n.contact_emails, "budget@example.com") &&
        (n.threshold_type == "Actual" ? n.threshold == 95 : n.threshold == 110)
      ])
    ])
    error_message = "Filtered and adopted RG workload budgets must both route actual 95 and forecast 110 alerts."
  }
  assert {
    condition = (
      azurerm_consumption_budget_subscription.subscription[0].amount == 200 &&
      length(azurerm_consumption_budget_subscription.subscription[0].notification) == 3 &&
      length(azurerm_consumption_budget_subscription.subscription[0].filter) == 0 &&
      alltrue([for n in azurerm_consumption_budget_subscription.subscription[0].notification :
        contains(n.contact_emails, "budget@example.com") &&
        (n.threshold_type == "Actual" ? contains([25, 75], n.threshold) : n.threshold == 90)
      ])
    )
    error_message = "Policy overrides must win; subscription aggregate must have no RG filters."
  }
  assert {
    condition = (
      length(azurerm_consumption_budget_subscription.workload) == 1 &&
      one(azurerm_consumption_budget_subscription.workload["example-Production"].filter[0].dimension).name == "ResourceGroupName" &&
      toset(one(azurerm_consumption_budget_subscription.workload["example-Production"].filter[0].dimension).values) == toset(["rg-example-prd-uksouth", "rg-example-prd-ukwest"]) &&
      azurerm_consumption_budget_subscription.workload["example-Production"].amount == 30
    )
    error_message = "One workload/environment budget must aggregate all declared RGs, not multiply the amount by region."
  }
  assert {
    condition = (
      length(azurerm_consumption_budget_resource_group.workload) == 2 &&
      azurerm_consumption_budget_resource_group.workload["platform-radar-Production"].name == "radar-monthly" &&
      azurerm_consumption_budget_resource_group.workload["platform-developer-portal-Production"].name == "idp-monthly-notification" &&
      alltrue([for b in azurerm_consumption_budget_resource_group.workload :
        b.time_period[0].start_date == "2026-10-01T00:00:00Z" && b.amount == 10 && length(b.filter) == 0
      ])
    )
    error_message = "Legacy RG budgets must retain exact names, amounts, start dates and unfiltered RG scope for import."
  }
}

run "reject_cross_subscription_scope" {
  command = plan
  variables {
    subscription_budget_policy = {
      monthly_budget      = 10
      subscription_id     = "11111111-1111-1111-1111-111111111111"
      scope               = "/subscriptions/22222222-2222-2222-2222-222222222222"
      budget_name         = "wrong-subscription"
      start_date          = "2026-11-01T00:00:00Z"
      actual_thresholds   = [95]
      forecast_thresholds = [110]
      contact_emails      = ["budget@example.com"]
    }
  }
  expect_failures = [terraform_data.budget_policy_validation]
}

run "reject_missing_direct_email" {
  command = plan
  variables {
    subscription_budget_policy = {
      monthly_budget      = 10
      subscription_id     = "11111111-1111-1111-1111-111111111111"
      scope               = "/subscriptions/11111111-1111-1111-1111-111111111111"
      budget_name         = "budget-sub-example"
      start_date          = "2026-04-01T00:00:00Z"
      actual_thresholds   = [95]
      forecast_thresholds = [110]
      contact_emails      = []
    }
  }
  expect_failures = [terraform_data.budget_policy_validation]
}

run "reject_empty_rg_inventory" {
  command = plan
  variables {
    workload_budget_policies = {
      "example-Production" = {
        monthly_budget       = 30
        subscription_id      = "11111111-1111-1111-1111-111111111111"
        scope                = "/subscriptions/11111111-1111-1111-1111-111111111111"
        budget_name          = "example-prd-monthly"
        start_date           = "2026-11-01T00:00:00Z"
        actual_thresholds    = [95]
        forecast_thresholds  = [110]
        contact_emails       = ["budget@example.com"]
        workload             = "example"
        environment          = "Production"
        environment_tag      = "prd"
        resource_group_names = []
      }
    }
  }
  expect_failures = [terraform_data.budget_policy_validation]
}

run "reject_invalid_thresholds" {
  command = plan
  variables {
    subscription_budget_policy = {
      monthly_budget      = 10
      subscription_id     = "11111111-1111-1111-1111-111111111111"
      scope               = "/subscriptions/11111111-1111-1111-1111-111111111111"
      budget_name         = "budget-sub-example"
      start_date          = "2026-04-01T00:00:00Z"
      actual_thresholds   = [-1]
      forecast_thresholds = [110]
      contact_emails      = ["budget@example.com"]
    }
  }
  expect_failures = [terraform_data.budget_policy_validation]
}

run "reject_unapproved_legacy_adoption" {
  command = plan
  variables {
    workload_budget_policies = {
      "platform-radar-Production" = {
        monthly_budget       = 10
        subscription_id      = "11111111-1111-1111-1111-111111111111"
        scope                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-platform-radar-prd-uksouth"
        budget_name          = "radar-monthly"
        start_date           = "2026-10-01T00:00:00Z"
        actual_thresholds    = [95]
        forecast_thresholds  = [110]
        contact_emails       = ["budget@example.com"]
        workload             = "platform-radar"
        environment          = "Production"
        environment_tag      = "prd"
        resource_group_names = ["rg-platform-radar-prd-uksouth"]
      }
    }
  }
  expect_failures = [terraform_data.budget_policy_validation]
}
