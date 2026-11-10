# Cost budgets and adoption

`platform-workloads` owns amounts and `cost_budget_policies` v1
([policy contract](https://github.com/frasermolyneux/platform-workloads/blob/main/docs/cost-budget-policy.md)).
Monitoring projects those policies into subscription deployment jobs; legacy
`monthly_budget` input and `subscription[0]` state addresses remain compatible.
Defaults for subscriptions and workloads are actual **95%** and forecast **110%**,
with direct email and additive Owner routing. Policy overrides are preserved.
Amounts stay in the producer, not duplicated here. No shutdown actions exist.

Subscription budgets are unfiltered backstops. Workload/environment budgets use
exact `ResourceGroupName` filters across declared regions, with one amount for the
whole environment. Do not sum overlapping subscription and workload budgets.
The adopted budgets below retain RG scope without filters.

Discovery must use the full budget ID
`<scope>/providers/Microsoft.Consumption/budgets/<name>` and filters, correlated
with RG `Workload`/`Environment` tags; budgets have no ordinary tag field.
`prevent_destroy` guards managed budget deletion/replacement; intentional
retirement requires separate review.

## Approval and deployment order

1. Deploy the producer policy first.
2. Deploy Radar and IDP ownership releases using
   `removed { lifecycle { destroy = false } }`. Verify both source states no
   longer own the budgets and the live IDs still exist. Never rename, delete,
   duplicate or manage a budget from two states.
3. Keep GitHub `COST_BUDGET_ADOPTION_COMPLETE` unset/false. It blocks subscription
   plans containing RG budgets. Main/scheduled deployment applies automatically;
   do not rely on an environment approval dialog.
4. With explicit operator approval, import the exact budgets below into the
   monitoring management-subscription state. Use its backend/tfvars, not core
   state, and the pinned CLI. Set `TF_VAR_subscription_name`,
   `TF_VAR_subscription_id`, `TF_VAR_monthly_budget`,
   `TF_VAR_subscription_budget_policy` and `TF_VAR_workload_budget_policies`
   from the updated core output, as the workflows do. For this approved manual
   session only, set `TF_VAR_legacy_budget_adoption_complete=true`; keep the
   GitHub variable false until both imports are verified.

| Source state address | Destination key in `azurerm_consumption_budget_resource_group.workload` |
|---|---|
| Radar: `azurerm_consumption_budget_resource_group.radar` | `platform-radar-Production` |
| IDP: `azurerm_consumption_budget_resource_group.portal` | `platform-developer-portal-Production` |

Preserve both budgets' start date `2026-10-01T00:00:00Z`, names and scopes:

```powershell
terraform -chdir=terraform-sub init -lockfile=readonly -reconfigure -backend-config=backends/prd.backend.hcl -backend-config=key=7760848c-794d-4a19-8cb2-52f71a21ac2b-terraform.tfstate
terraform -chdir=terraform-sub import -var-file=tfvars/prd.tfvars 'azurerm_consumption_budget_resource_group.workload["platform-radar-Production"]' '/subscriptions/7760848c-794d-4a19-8cb2-52f71a21ac2b/resourceGroups/rg-platform-radar-prd-uksouth/providers/Microsoft.Consumption/budgets/radar-monthly'
terraform -chdir=terraform-sub import -var-file=tfvars/prd.tfvars 'azurerm_consumption_budget_resource_group.workload["platform-developer-portal-Production"]' '/subscriptions/7760848c-794d-4a19-8cb2-52f71a21ac2b/resourceGroups/rg-platform-developer-portal-prd-uksouth/providers/Microsoft.Consumption/budgets/idp-monthly-notification'
terraform -chdir=terraform-sub plan -var-file=tfvars/prd.tfvars
```

5. Review refreshed core and every subscription plan. Require no budget
   deletion/replacement, correct scope/filters, and direct email on each alert.
   Verify both destination state IDs before approving the GitHub variable
   `COST_BUDGET_ADOPTION_COMPLETE=true`. Deploy monitoring Development then
   Production core/subscription stacks.
6. Update IDP discovery after budgets exist. Verify actual email receipt
   separately; delivery remains unverified.

Validation commands are in [AGENTS.md](../AGENTS.md); both roots also run
`terraform test`. Repeat state-backed plans after the producer publishes policy.
