# Cost budgets

`platform-workloads` owns budget amounts and publishes the required version 1
`cost_budget_policies` contract ([policy contract](https://github.com/frasermolyneux/platform-workloads/blob/main/docs/cost-budget-policy.md)).
Monitoring consumes that contract for every subscription. The `monthly_budget`
field in the monitoring `subscriptions` output is a convenience compatibility
field derived from the version 1 policy; subscription deployments consume the
policy object directly. There is no legacy-input fallback.

Subscription budgets are unfiltered backstops. Workload/environment budgets use
exact `ResourceGroupName` filters across declared regions, with one amount for
the whole environment. Do not sum overlapping subscription and workload budgets.
Defaults for subscription and workload policies are actual **95%** and forecast
**110%**, with direct email and additive Owner routing; policy overrides are
preserved. No shutdown actions exist.

## Existing production workload budgets

These existing budgets are managed at resource-group scope and retain their
original Azure IDs, Terraform addresses, and start dates. Amounts and alert
settings are owned by the producer policy.

| Workload | Resource group | Budget name | Terraform address | Start date |
|---|---|---|---|---|
| Radar | `rg-platform-radar-prd-uksouth` | `radar-monthly` | `azurerm_consumption_budget_resource_group.workload["platform-radar-Production"]` | `2026-10-01T00:00:00Z` |
| IDP | `rg-platform-developer-portal-prd-uksouth` | `idp-monthly-notification` | `azurerm_consumption_budget_resource_group.workload["platform-developer-portal-Production"]` | `2026-10-01T00:00:00Z` |

Their full IDs are:

```text
/subscriptions/7760848c-794d-4a19-8cb2-52f71a21ac2b/resourceGroups/rg-platform-radar-prd-uksouth/providers/Microsoft.Consumption/budgets/radar-monthly
/subscriptions/7760848c-794d-4a19-8cb2-52f71a21ac2b/resourceGroups/rg-platform-developer-portal-prd-uksouth/providers/Microsoft.Consumption/budgets/idp-monthly-notification
```

Budget discovery uses the full ID
`<scope>/providers/Microsoft.Consumption/budgets/<name>` and filters, correlated
with resource-group `Workload` and `Environment` tags; budgets have no ordinary
tag field. `prevent_destroy` guards managed budget deletion/replacement. Do not
rename, delete, duplicate, or manage a budget from multiple Terraform states.

## Operations

1. Make amount, scope, threshold, or contact changes in the producer policy.
   Do not duplicate budget amounts in this repository.
2. Verify the monitoring producer projection and the affected subscription
   plans. Confirm exact budget IDs, names, scopes, filters, start dates, and
   notification thresholds; retain the normal no-delete/no-replacement guard.
3. Merge and deploy monitoring through the standard workflow. Main and scheduled
   deployment jobs apply automatically; do not rely on an environment approval
   dialog as a safeguard.
4. Verify live Azure properties after deployment. Confirm actual alert delivery
   separately; a successful deployment does not prove that email was received.

Any intentional budget retirement or identity change requires a separately
reviewed change. Preserve the published policy and Terraform resource identities
unless that review explicitly authorizes otherwise.

Validation commands are in [AGENTS.md](../AGENTS.md); both Terraform roots also
run `terraform test`.
