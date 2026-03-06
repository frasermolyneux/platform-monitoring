resource "azurerm_consumption_budget_subscription" "subscription" {
  count = var.monthly_budget > 0 ? 1 : 0

  name            = "budget-${var.subscription_name}"
  subscription_id = "/subscriptions/${var.subscription_id}"

  amount     = var.monthly_budget
  time_grain = "Monthly"

  time_period {
    start_date = "2026-04-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 50
    threshold_type = "Actual"
    operator       = "GreaterThanOrEqualTo"

    contact_roles = ["Owner"]
  }

  notification {
    enabled        = true
    threshold      = 80
    threshold_type = "Actual"
    operator       = "GreaterThanOrEqualTo"

    contact_roles = ["Owner"]
  }

  notification {
    enabled        = true
    threshold      = 100
    threshold_type = "Actual"
    operator       = "GreaterThanOrEqualTo"

    contact_roles = ["Owner"]
  }

  notification {
    enabled        = true
    threshold      = 110
    threshold_type = "Forecasted"
    operator       = "GreaterThanOrEqualTo"

    contact_roles = ["Owner"]
  }
}
