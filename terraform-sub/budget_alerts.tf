locals {
  budget_subscription_scope = "/subscriptions/${var.subscription_id}"
  # Older platform-workloads states publish only monthly_budget.
  subscription_budget_policy = var.subscription_budget_policy != null ? var.subscription_budget_policy : {
    monthly_budget      = var.monthly_budget
    subscription_id     = var.subscription_id
    scope               = local.budget_subscription_scope
    budget_name         = "budget-${var.subscription_name}"
    start_date          = "2026-04-01T00:00:00Z"
    actual_thresholds   = toset([95])
    forecast_thresholds = toset([110])
    contact_emails      = toset(["frasermolyneux@mx-mail.io"])
  }
  all_budget_policies = merge({ subscription = local.subscription_budget_policy }, var.workload_budget_policies)
  budget_notifications = {
    for key, policy in local.all_budget_policies : key => concat(
      [for threshold in policy.actual_thresholds : { threshold = threshold, threshold_type = "Actual" }],
      [for threshold in policy.forecast_thresholds : { threshold = threshold, threshold_type = "Forecasted" }]
    )
  }
  workload_subscription_budgets = {
    for key, policy in var.workload_budget_policies : key => policy
    if lower(policy.scope) == lower(local.budget_subscription_scope)
  }
  workload_resource_group_budgets = {
    for key, policy in var.workload_budget_policies : key => policy
    if lower(policy.scope) != lower(local.budget_subscription_scope)
  }
}

resource "terraform_data" "budget_policy_validation" {
  input = local.all_budget_policies

  lifecycle {
    precondition {
      condition     = length(local.workload_resource_group_budgets) == 0 || var.legacy_budget_adoption_complete
      error_message = "RG budget adoption is blocked. Release source ownership without destroy, import both exact legacy IDs, verify central state, then approve COST_BUDGET_ADOPTION_COMPLETE=true. See docs/cost-budgets.md."
    }
    precondition {
      condition = alltrue([for policy in values(local.all_budget_policies) :
        lower(policy.subscription_id) == lower(var.subscription_id) &&
        policy.monthly_budget >= 0 &&
        length(policy.contact_emails) > 0 &&
        alltrue([for email in policy.contact_emails : can(regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$", email))]) &&
        length(policy.actual_thresholds) + length(policy.forecast_thresholds) >= 1 &&
        length(policy.actual_thresholds) + length(policy.forecast_thresholds) <= 5 &&
        alltrue([for threshold in setunion(policy.actual_thresholds, policy.forecast_thresholds) : threshold > 0 && threshold <= 1000]) &&
        can(regex("^\\d{4}-\\d{2}-01T00:00:00Z$", policy.start_date)) &&
        length(trimspace(policy.budget_name)) > 0
      ])
      error_message = "Budget policies require this subscription, nonnegative amounts, direct email, 1-5 notifications with thresholds in (0,1000], a stable name and first-of-month UTC start_date."
    }
    precondition {
      condition = (
        lower(local.subscription_budget_policy.scope) == lower(local.budget_subscription_scope) &&
        alltrue([for policy in values(var.workload_budget_policies) :
          policy.monthly_budget > 0 &&
          length(policy.resource_group_names) > 0 &&
          alltrue([for name in policy.resource_group_names : length(trimspace(name)) > 0]) &&
          (lower(policy.scope) == lower(local.budget_subscription_scope) ||
            (length(policy.resource_group_names) == 1 &&
              lower(policy.scope) == lower("${local.budget_subscription_scope}/resourceGroups/${try(one(policy.resource_group_names), "")}")
          ))
        ])
      )
      error_message = "Subscription budgets must cover the whole subscription. Workload budgets must use exact RG names within this subscription, or the matching single RG scope."
    }
    precondition {
      condition = length(distinct([for policy in values(local.all_budget_policies) :
        lower("${policy.scope}/providers/Microsoft.Consumption/budgets/${policy.budget_name}")
      ])) == length(local.all_budget_policies) && !contains(keys(var.workload_budget_policies), "subscription")
      error_message = "Budget policies must have unique full Azure budget IDs; the key subscription is reserved."
    }
  }
}

resource "azurerm_consumption_budget_subscription" "subscription" {
  count = local.subscription_budget_policy.monthly_budget > 0 ? 1 : 0

  name            = local.subscription_budget_policy.budget_name
  subscription_id = local.subscription_budget_policy.scope
  amount          = local.subscription_budget_policy.monthly_budget
  time_grain      = "Monthly"

  time_period {
    start_date = local.subscription_budget_policy.start_date
  }

  dynamic "notification" {
    for_each = local.budget_notifications.subscription
    content {
      enabled        = true
      threshold      = notification.value.threshold
      threshold_type = notification.value.threshold_type
      operator       = "GreaterThanOrEqualTo"
      contact_emails = local.subscription_budget_policy.contact_emails
      contact_roles  = ["Owner"]
    }
  }

  lifecycle {
    prevent_destroy = true
  }
  depends_on = [terraform_data.budget_policy_validation]
}

resource "azurerm_consumption_budget_subscription" "workload" {
  for_each = local.workload_subscription_budgets

  name            = each.value.budget_name
  subscription_id = each.value.scope
  amount          = each.value.monthly_budget
  time_grain      = "Monthly"

  time_period {
    start_date = each.value.start_date
  }

  filter {
    dimension {
      name     = "ResourceGroupName"
      operator = "In"
      values   = each.value.resource_group_names
    }
  }

  dynamic "notification" {
    for_each = local.budget_notifications[each.key]
    content {
      enabled        = true
      threshold      = notification.value.threshold
      threshold_type = notification.value.threshold_type
      operator       = "GreaterThanOrEqualTo"
      contact_emails = each.value.contact_emails
      contact_roles  = ["Owner"]
    }
  }

  lifecycle {
    prevent_destroy = true
  }
  depends_on = [terraform_data.budget_policy_validation]
}

resource "azurerm_consumption_budget_resource_group" "workload" {
  for_each = local.workload_resource_group_budgets

  name              = each.value.budget_name
  resource_group_id = each.value.scope
  amount            = each.value.monthly_budget
  time_grain        = "Monthly"

  time_period {
    start_date = each.value.start_date
  }

  dynamic "notification" {
    for_each = local.budget_notifications[each.key]
    content {
      enabled        = true
      threshold      = notification.value.threshold
      threshold_type = notification.value.threshold_type
      operator       = "GreaterThanOrEqualTo"
      contact_emails = each.value.contact_emails
      contact_roles  = ["Owner"]
    }
  }

  lifecycle {
    prevent_destroy = true
  }
  depends_on = [terraform_data.budget_policy_validation]
}
