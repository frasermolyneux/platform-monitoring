mock_provider "azurerm" {}
mock_provider "azurerm" {
  alias = "geolocation"
}
mock_provider "azurerm" {
  alias = "portal"
}
mock_provider "azurerm" {
  alias = "noncritical"
}
mock_provider "azuread" {}
mock_provider "random" {}

variables {
  environment     = "prd"
  subscription_id = "11111111-1111-1111-1111-111111111111"
  noncritical_log_analytics = {
    enabled                         = false
    subscription_id                 = "11111111-1111-1111-1111-111111111111"
    resource_group_name             = "rg-test"
    workspace_name                  = "log-test"
    linux_data_collection_rule_name = "dcr-test"
  }
  platform_workloads_state = {
    resource_group_name  = "rg-state"
    storage_account_name = "statetest"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    subscription_id      = "11111111-1111-1111-1111-111111111111"
    tenant_id            = "11111111-1111-1111-1111-111111111111"
  }
}

run "version_one_filters_by_subscription_and_deployment_environment" {
  command = plan
  plan_options {
    target = [data.terraform_remote_state.platform_workloads]
  }
  override_data {
    target = data.terraform_remote_state.platform_workloads
    values = {
      outputs = {
        subscriptions = {
          example = {
            name            = "sub-example"
            subscription_id = "11111111-1111-1111-1111-111111111111"
            environment     = "prd"
          }
          other = {
            name            = "sub-other"
            subscription_id = "22222222-2222-2222-2222-222222222222"
            environment     = "dev"
          }
          workload-only = {
            name            = "sub-workload-only"
            subscription_id = "33333333-3333-3333-3333-333333333333"
            environment     = "prd"
            monthly_budget  = null
          }
        }
        cost_budget_policies = {
          version = 1
          subscriptions = {
            example = {
              monthly_budget      = 150
              subscription_id     = "11111111-1111-1111-1111-111111111111"
              scope               = "/subscriptions/11111111-1111-1111-1111-111111111111"
              budget_name         = "budget-sub-example"
              start_date          = "2026-04-01T00:00:00Z"
              actual_thresholds   = [95]
              forecast_thresholds = [110]
              contact_emails      = ["budget@example.com"]
              rationale           = null
            }
            other = {
              monthly_budget      = 50
              subscription_id     = "22222222-2222-2222-2222-222222222222"
              scope               = "/subscriptions/22222222-2222-2222-2222-222222222222"
              budget_name         = "budget-sub-other"
              start_date          = "2026-04-01T00:00:00Z"
              actual_thresholds   = [95]
              forecast_thresholds = [110]
              contact_emails      = ["budget@example.com"]
              rationale           = "Fixture"
            }
          }
          workload_environments = {
            example-Production = {
              subscription_id = "11111111-1111-1111-1111-111111111111"
              monthly_budget  = 30
              rationale       = null
            }
            other-Development = {
              subscription_id = "22222222-2222-2222-2222-222222222222"
              monthly_budget  = 10
            }
            workload-only-Production = {
              subscription_id = "33333333-3333-3333-3333-333333333333"
              monthly_budget  = 25
              rationale       = "Workload-only subscription"
            }
          }
        }
      }
    }
  }
  assert {
    condition = (
      length(output.subscriptions) == 2 &&
      one([for sub in output.subscriptions : sub if sub.name == "sub-example"]).monthly_budget == 150 &&
      one([for sub in output.subscriptions : sub if sub.name == "sub-example"]).subscription_budget_policy.budget_name == "budget-sub-example" &&
      one([for sub in output.subscriptions : sub if sub.name == "sub-example"]).subscription_budget_policy.actual_thresholds == [95] &&
      one([for sub in output.subscriptions : sub if sub.name == "sub-example"]).subscription_budget_policy.forecast_thresholds == [110] &&
      one([for sub in output.subscriptions : sub if sub.name == "sub-example"]).subscription_budget_policy.rationale == null &&
      one([for sub in output.subscriptions : sub if sub.name == "sub-example"]).workload_budget_policies["example-Production"].rationale == null &&
      keys(one([for sub in output.subscriptions : sub if sub.name == "sub-example"]).workload_budget_policies) == ["example-Production"] &&
      one([for sub in output.subscriptions : sub if sub.name == "sub-workload-only"]).monthly_budget == 0 &&
      one([for sub in output.subscriptions : sub if sub.name == "sub-workload-only"]).subscription_budget_policy == null &&
      keys(one([for sub in output.subscriptions : sub if sub.name == "sub-workload-only"]).workload_budget_policies) == ["workload-only-Production"]
    )
    error_message = "Version 1 policies must preserve workload-only subscriptions and project each policy only into its subscription and environment."
  }
}

run "reject_unknown_contract_version" {
  command = plan
  plan_options {
    target = [data.terraform_remote_state.platform_workloads]
  }
  override_data {
    target = data.terraform_remote_state.platform_workloads
    values = {
      outputs = {
        subscriptions        = {}
        cost_budget_policies = { version = 2, subscriptions = {}, workload_environments = {} }
      }
    }
  }
  expect_failures = [output.subscriptions]
}

run "reject_missing_subscription_policy" {
  command = plan
  plan_options {
    target = [data.terraform_remote_state.platform_workloads]
  }
  override_data {
    target = data.terraform_remote_state.platform_workloads
    values = {
      outputs = {
        subscriptions = {
          example = {
            name            = "sub-example"
            subscription_id = "11111111-1111-1111-1111-111111111111"
            environment     = "prd"
            monthly_budget  = 150
          }
        }
        cost_budget_policies = { version = 1, subscriptions = {}, workload_environments = {} }
      }
    }
  }
  expect_failures = [output.subscriptions]
}
