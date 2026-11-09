# Cost budget deployment and adoption

`platform-workloads` is the sole source of subscription amounts and workload/
environment policy. Monitoring consumes its additive `cost_budget_policies`
version 1 output, projects policies into the matching subscription matrix, and
deploys budgets through `terraform-sub`. The legacy `subscriptions.monthly_budget`
field and `azurerm_consumption_budget_subscription.subscription[0]` address remain
compatible. An older producer state supplies no workload policies; deploy the
producer first to activate workload coverage.

Each policy includes `monthly_budget`, bare `subscription_id`, full ARM `scope`,
`budget_name`, immutable first-of-month `start_date`, `actual_thresholds`,
`forecast_thresholds`, and `contact_emails`. Workload policies additionally include
`workload`, `environment`, `environment_tag`, and `resource_group_names`.
Producer defaults are actual 50/80/100% and forecast 100%, with direct delivery to
frasermolyneux@mx-mail.io; overrides are retained. Owner routing remains additive.
Azure supports at most five notifications per budget. No shutdown or remediation
actions are configured.

## Scope and discovery contract

Subscription budgets are unfiltered aggregate backstops; never sum their amount
with workload amounts to calculate the estate budget. Workload/environment budgets
normally have subscription scope and an exact `ResourceGroupName` dimension (`In`)
covering all declared RGs across regions. The amount is applied once to the whole
environment, not once per RG. The two adopted exceptions below retain actual RG
scope and no filters.

The canonical budget ID is
`<scope>/providers/Microsoft.Consumption/budgets/<budget_name>`. New workload names
are `<workload>-<environment_tag>-monthly`; existing subscription names stay
`budget-<subscription-name>`. Consumers must inspect the full ID, scope and filters,
then correlate exact RG names and their `Workload`/`Environment` tags. Budget
resources have no ordinary tag field. Do not infer identity from display name or
sum overlapping aggregate and workload budgets.

`prevent_destroy` guards managed budgets against accidental removal, scope,
name or start-date replacement, including accidentally disabling an existing
budget. Intentional retirement requires a separately reviewed change. Removing
the entire resource block bypasses Terraform's lifecycle guard and is not an
approved retirement procedure.

## Existing budget adoption: approval required, not performed by this PR

Read-only Azure inventory on 2026-11-09 confirmed both existing budgets at GBP10
per month, Monthly, start `2026-10-01T00:00:00Z`, no filters. The monitoring
management subscription state contains only its subscription budget, not these
RG budgets. They are currently owned by the source workload states:

| Source state address | Destination in monitoring `terraform-sub` | RG / existing budget name |
|---|---|---|
| Radar: `azurerm_consumption_budget_resource_group.radar` | `azurerm_consumption_budget_resource_group.workload["platform-radar-Production"]` | `rg-platform-radar-prd-uksouth` / `radar-monthly` |
| IDP: `azurerm_consumption_budget_resource_group.portal` | `azurerm_consumption_budget_resource_group.workload["platform-developer-portal-Production"]` | `rg-platform-developer-portal-prd-uksouth` / `idp-monthly-notification` |

Both use subscription `7760848c-794d-4a19-8cb2-52f71a21ac2b`. Do not create
replacement budgets under new names. Do not delete the live budgets or let two
Terraform states manage the same ID. The following steps need explicit operator
approval; no apply, import, state removal or Azure change was executed here.

1. Merge and deploy `platform-workloads` policy first. Review its evidence-based
   amounts and stable IDs. Normal budgets exclude the known one-off notification
   incident only for baseline setting; cost reporting must still include it.
   Do not linearly extrapolate early-month observations.
2. Deploy the source Radar and IDP ownership-transfer PRs using
   `removed { lifecycle { destroy = false } }`. Confirm each source plan only
   relinquishes its budget (and Radar's budget-only clock), never destroys the
   live budget. Verify the source state no longer owns the budget and the ARM ID
   still exists before proceeding.
3. Keep `COST_BUDGET_ADOPTION_COMPLETE` unset/false in GitHub variables until
   transfer and import are complete. The Terraform gate defaults to false and
   blocks any subscription plan containing RG budgets. The observed Production
   environment has no required-reviewer protection; do not assume there is an
   approval dialog. Main/scheduled deployment applies automatically, so gate
   release itself requires explicit operator approval.
4. With the pinned `terraform-sub/.terraform-version` CLI, initialize the exact
   Production subscription backend and supply policy inputs projected from the
   updated core plan/output. The management key is
   `7760848c-794d-4a19-8cb2-52f71a21ac2b-terraform.tfstate` in
   `sa74f04c5f984e/tfstate`, not the core `terraform.tfstate`. Set
   `TF_VAR_subscription_name`, `TF_VAR_subscription_id`, `TF_VAR_monthly_budget`,
   `TF_VAR_subscription_budget_policy` (JSON) and `TF_VAR_workload_budget_policies`
   (JSON) exactly as the workflow does. For this approved manual import session
   only, set `TF_VAR_legacy_budget_adoption_complete=true` after verifying source
   release; keep the GitHub variable false so automatic deployment stays blocked.
   Then, only after approval, run:

```powershell
terraform -chdir=terraform-sub init -lockfile=readonly -reconfigure -backend-config=backends/prd.backend.hcl -backend-config=key=7760848c-794d-4a19-8cb2-52f71a21ac2b-terraform.tfstate
terraform -chdir=terraform-sub import -var-file=tfvars/prd.tfvars 'azurerm_consumption_budget_resource_group.workload["platform-radar-Production"]' '/subscriptions/7760848c-794d-4a19-8cb2-52f71a21ac2b/resourceGroups/rg-platform-radar-prd-uksouth/providers/Microsoft.Consumption/budgets/radar-monthly'
terraform -chdir=terraform-sub import -var-file=tfvars/prd.tfvars 'azurerm_consumption_budget_resource_group.workload["platform-developer-portal-Production"]' '/subscriptions/7760848c-794d-4a19-8cb2-52f71a21ac2b/resourceGroups/rg-platform-developer-portal-prd-uksouth/providers/Microsoft.Consumption/budgets/idp-monthly-notification'
terraform -chdir=terraform-sub plan -var-file=tfvars/prd.tfvars
```

5. Review the refreshed core and **every subscription** plan after producer
   deployment. Require no budget deletion/replacement, unchanged legacy names/
   scope/start dates, correct RG filters and direct email on every notification.
   A missing import must block deployment, not be worked around by renaming.
   Verify both destination state IDs, then explicitly approve setting the GitHub
   repository variable `COST_BUDGET_ADOPTION_COMPLETE=true` (or an equivalent
   environment-level value). This permits automatic central management; do not set
   it before import. Deploy monitoring Development then Production core/subscription
   stacks. A future environment override must not silently bypass this gate.
6. Enable/update IDP discovery after policy and budgets exist. Verify full IDs,
   filters and RG tag mapping. Validate actual email receipt separately through
   an approved operational procedure. The shared-subscription 50% notification
   fired on October 24; delivery is **unverified**, not a successful delivery test.

## Validation

Run pinned CLI `fmt -check -recursive`, `init -backend=false -lockfile=readonly`,
and `validate` for both roots, plus `terraform -chdir=terraform test` and
`terraform -chdir=terraform-sub test`.
Mock-provider tests cover defaults, overrides, aggregate versus RG-filtered
scoping, both adopted identities, producer-to-matrix projection and rejection of
invalid contract versions, scope and direct routing.
Production read-only plans use the `run-prd-plan` PR label and Production approval;
they must be repeated after the producer state publishes version 1 policies.
