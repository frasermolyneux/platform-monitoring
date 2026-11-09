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

run "legacy_output_compatible" {
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
      }
    }
  }
  assert {
    condition = (
      output.subscriptions[0].name == "sub-example" &&
      output.subscriptions[0].monthly_budget == 150 &&
      output.subscriptions[0].subscription_budget_policy == null &&
      length(output.subscriptions[0].workload_budget_policies) == 0
    )
    error_message = "Older deployed producer state must retain the existing subscription contract."
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
            monthly_budget  = 150
          }
          other = {
            name            = "sub-other"
            subscription_id = "22222222-2222-2222-2222-222222222222"
            environment     = "dev"
            monthly_budget  = 50
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
              actual_thresholds   = [50, 80, 100]
              forecast_thresholds = [100]
              contact_emails      = ["budget@example.com"]
              rationale           = "Fixture"
            }
            other = {
              monthly_budget      = 50
              subscription_id     = "22222222-2222-2222-2222-222222222222"
              scope               = "/subscriptions/22222222-2222-2222-2222-222222222222"
              budget_name         = "budget-sub-other"
              start_date          = "2026-04-01T00:00:00Z"
              actual_thresholds   = [50, 80, 100]
              forecast_thresholds = [100]
              contact_emails      = ["budget@example.com"]
              rationale           = "Fixture"
            }
          }
          workload_environments = {
            example-Production = {
              subscription_id = "11111111-1111-1111-1111-111111111111"
              monthly_budget  = 30
            }
            other-Development = {
              subscription_id = "22222222-2222-2222-2222-222222222222"
              monthly_budget  = 10
            }
          }
        }
      }
    }
  }
  assert {
    condition = (
      length(output.subscriptions) == 1 &&
      output.subscriptions[0].subscription_budget_policy.budget_name == "budget-sub-example" &&
      keys(output.subscriptions[0].workload_budget_policies) == ["example-Production"]
    )
    error_message = "Policies must be projected only into the exact subscription and matching deployment environment matrix."
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
