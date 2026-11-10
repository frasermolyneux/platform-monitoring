# Cost budgets

`platform-workloads` owns budget amounts and publishes the version 1
`cost_budget_policies` contract ([policy contract](https://github.com/frasermolyneux/platform-workloads/blob/main/docs/cost-budget-policy.md)).
Monitoring consumes that contract for every subscription. Subscription budgets
are optional; when the producer omits a subscription policy, monitoring creates
no subscription backstop. Workload policies remain independent and can create
their budgets without a subscription budget. The `monthly_budget` field in the
monitoring `subscriptions` output is derived from the version 1 policy; there is
no legacy-input fallback.

Subscription budgets are unfiltered backstops. Workload/environment budgets use
exact `ResourceGroupName` filters across declared regions, with one amount for
the whole environment. Do not sum overlapping subscription and workload budgets.
The producer policy defines amounts, notification thresholds and contacts;
policy overrides are preserved. No shutdown actions exist.

The producer policy and deployed Terraform state are authoritative for current
budget IDs, resource names, start dates, scopes and notification settings; avoid
copying live configuration snapshots here. `prevent_destroy` guards managed
budget deletion/replacement. Do not rename, delete, duplicate, or manage a
budget from multiple Terraform states.

## Operations

1. Make amount, scope, threshold, or contact changes in the producer policy.
   Do not duplicate budget amounts in this repository.
2. Verify the monitoring producer projection and affected subscription plans.
   Confirm policy identity, scope, filters and notification settings; retain the
   normal no-delete/no-replacement guard.
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
