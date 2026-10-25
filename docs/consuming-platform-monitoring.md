# Consuming Platform Monitoring

The platform-monitoring resources are designed to be long-lived and shared across downstream workloads. Both development and production environments are kept online; the development environment is *not* recycled on a schedule, so remote state references remain stable between runs.

## Process health contract

`contract/process-health-policy.json` owns the Portal process-health bindings,
cadence, freshness and job completion deadlines. Workloads compile the mirrored
`ProcessHealthTelemetry.cs`; status only consumes the classified observations.
Synchronize the explicitly selected repository roots with
`python contract\sync-process-health.py --target <producer-root> --policy-only-target <status-root>`,
then repeat with `--check` before release. Never edit the consumer mirrors.

The agent publishes expected-fleet progress and ban delivery/import convergence.
Intent comes from the complete configured server inventory, including enabled
capabilities whose agents cannot start. A quiet log or unchanged ban content is
not failure; Service Bus publication is not proof of a persisted import. Individual
missing agents and overdue deliveries contribute Degraded, not fleet Outage.
Sync persists actual job outcomes in a private container in its existing host
storage, preserving original last-success/failure times across restarts and weekly
schedules. Partial failures cannot produce successful job completion.

Publishers emit four aggregate `ProcessHealthSnapshot` and seven private
`ProcessJobSnapshot` records per five minutes per environment. Public records
contain counts and source identity only; server identities, paths, errors and ban
contents stay private. Missing, stale or unobserved evidence is Unknown, never
healthy by default. Existing Sync alerts consume the contract using their current
rule identities, evaluation schedules and action groups; no per-server paid
alert series or new alert resources are introduced.

At the reviewed UK South Analytics ingestion rate of US$2.88/GB, allowing 4 KiB
per billed record gives 190,080 records/30 days across dev and production,
approximately US$2.24 ingestion. A conservative 300,000 existing Hot LRS operations
at the higher reviewed write rate (US$0.059/10,000, versus US$0.0047 reads) add
US$1.77, with negligible stored state. Expected usage is lower, approximately
US$3/month combined. This is below the approved US$5 incremental allowance,
not a hard billing cap; significant cadence, record-size or environment increases
require a new estimate. Existing always-on compute, workspaces, storage accounts
and alert-series counts are unchanged. Verify actual billed record sizes after
producer rollout; do not trade away monitoring coverage to conceal cost.

Deploy producers and their existing alert updates before status consumption.
Verify all four identities, roles and original timestamps in the correct
Application Insights resource; then require the status `--refresh-monitoring`
preflight. First-ever jobs remain Unknown until they actually complete, including
the weekly image job. Do not fabricate initial successes or backfill public history.
Portal-web remains the detailed operational surface; status publishes aggregate
capability impact only.

## What this project provides

- Central Log Analytics workspaces exposed through `log_analytics_workspaces`, including a stable `primary` workspace and optional service classes such as `noncritical`
- Centrally managed data collection rules exposed through `data_collection_rules`, including the production Linux `linux_noncritical` profile
- The original primary workspace output remains available as `log_analytics` for compatibility
- Severity-based Azure Monitor action groups (critical, high, moderate, low, informational) exposed via the `monitor_action_groups` output
- A Production-only Entra-secured webhook group exposed separately as `status_evidence`, without changing the human notification contract
- Subscription metadata surfaced through the `subscriptions` output for convenience

## Access and permissions

Platform identities are provisioned via the [platform-workloads](https://github.com/frasermolyneux/platform-workloads) project. Each workload gets a service principal (and optional deploy-script user-assigned identity) with at least `Reader` on its subscription. The critical prerequisite for consumption is **remote state access**: ensure the workload identity has `Storage Blob Data Reader` on the platform-monitoring state storage account so `terraform_remote_state` can read outputs (platform-workloads can grant this via `requires_terraform_state_access`). After state access, layer on the following as needed:

- Publish diagnostics to the shared Log Analytics workspace: add `Log Analytics Contributor` (or `Monitoring Contributor`) on the workspace scope exposed by this repo's outputs.
- Create or update alert rules targeting the shared action groups: add `Monitoring Contributor` scoped to the subscription or resource groups where alerts will live.
- Query workspace data (for log alerts or ad-hoc KQL): add `Log Analytics Reader` if the default `Reader` assignment is insufficient.

Because the platform-monitoring environments stay online (dev is not cycled), these role assignments remain stable for long-running pipelines and state reads.

## Remote state locations

The Terraform backend configurations live in the repository under `terraform/backends/` and are stable for each environment:
- Development: `terraform/backends/dev.backend.hcl`
- Production: `terraform/backends/prd.backend.hcl`

Use the matching backend settings in your consumers so you pull the correct environment state. Because the state containers are stable and not rotated, consumers can safely reference these backends for long-lived pipelines.

## Terraform consumption example (azurerm backend)

The pattern below mirrors the setup used in `platform-sitewatch-func`: environment-specific backend settings are passed in as variables, then the remote state outputs are consumed for alerts and diagnostics.

```hcl
variable "platform_monitoring_state" {
  description = "Backend config for platform-monitoring remote state"
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    key                  = string
    subscription_id      = string
    tenant_id            = string
  })
}

data "terraform_remote_state" "platform_monitoring" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.platform_monitoring_state.resource_group_name
    storage_account_name = var.platform_monitoring_state.storage_account_name
    container_name       = var.platform_monitoring_state.container_name
    key                  = var.platform_monitoring_state.key
    use_oidc             = true
    subscription_id      = var.platform_monitoring_state.subscription_id
    tenant_id            = var.platform_monitoring_state.tenant_id
  }
}

locals {
  log_analytics_workspace = coalesce(
    data.terraform_remote_state.platform_monitoring.outputs.log_analytics_workspaces["noncritical"],
    data.terraform_remote_state.platform_monitoring.outputs.log_analytics_workspaces["primary"]
  )
  log_analytics_workspace_id = local.log_analytics_workspace.id
  log_analytics_workspace_rg = local.log_analytics_workspace.resource_group_name
  critical_action_group_id   = data.terraform_remote_state.platform_monitoring.outputs.monitor_action_groups["critical"].id
  linux_data_collection_rule = data.terraform_remote_state.platform_monitoring.outputs.data_collection_rules["linux_noncritical"]
}

resource "azurerm_monitor_metric_alert" "app_health" {
  name                = "app-health"
  resource_group_name = azurerm_resource_group.app.name
  scopes              = [azurerm_function_app.app.id]
  severity            = 2
  description         = "Error rate above threshold"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = local.critical_action_group_id
  }
}

resource "azurerm_monitor_diagnostic_setting" "app_logs" {
  name                       = "send-logs"
  target_resource_id         = azurerm_function_app.app.id
  log_analytics_workspace_id = local.log_analytics_workspace_id

  enabled_log {
    category = "FunctionAppLogs"
  }
}
```

Adjust the backend values to the production settings when wiring production workloads; the file `terraform/backends/prd.backend.hcl` contains the exact configuration.

## Usage notes

- Prefer consuming the remote state rather than duplicating Log Analytics or action groups; this keeps ownership and alert routing consistent across workloads.
- Select a workspace by service class from `log_analytics_workspaces`. The `noncritical` key is `null` where that class is disabled, so environment-spanning consumers should fall back to `primary` as shown above.
- Production bare-metal telemetry is intended to use `noncritical`, which is centrally owned by `platform-monitoring` but hosted in the Visual Studio Enterprise subscription to consume its credit allowance.
- Linux hosts should consume `data_collection_rules["linux_noncritical"]` rather than defining their own equivalent collection policy. The rule collects heartbeat through the Azure Monitor Agent, authentication syslog at Info or higher, selected system syslog at Warning or higher, and a small set of 60-second capacity and health counters.
- The Linux rule collects `local0` at Info or higher for structured platform operational events. The shared backup-failure query alert sends High-severity notifications when `platform-backup` or `platform-backup-health` reports a failed or stale backup.
- Shared capacity alerts use the Linux logical-disk counters: warning below 20 percent or 100 GiB free, and High-severity notification below 10 percent or 50 GiB free.
- Managed database health events from `platform-database-health` trigger warning or High-severity notifications when connection utilisation or binary-log bytes cross their host-managed thresholds.
- Production backup-health monitoring currently expects `ns346663` and `ns5019527`. `ns512615` is intentionally excluded while its platform backup agent remains disabled; delegated workload owners must arrange and monitor their own backups.
- The `noncritical` workspace is for telemetry that may be filtered, sampled, or dropped without hiding an immediate service-impacting condition. It has local shared-key authentication disabled, so consumers must use Azure identities.
- Choose the action group severity that matches your alert rules and pass the `id` to `azurerm_monitor_metric_alert` or `azurerm_monitor_activity_log_alert` configurations.
- The central Log Analytics workspace can be used as the target for `azurerm_monitor_diagnostic_setting` or query targets in log-based alerts; use the `workspace_id` output when configuring those resources.

## Cost-bounded workload baselines

`platform-monitoring` remains the strategic monitoring owner. Workload
repositories own instrumentation and workload-specific alert definitions while
consuming the shared workspaces, collection rules and severity action groups;
do not move Terraform state simply to centralise ownership.

Use **Service → Component → Check** for public status. Stable workload/component
IDs map private evidence to the correct component; multiple independent checks
aggregate into that component, and components into their service. Share the same
logical check identity for dependencies displayed on both brands. Missing or stale
expected signals are unknown, never proof of health. Availability measurements do
not replace private queue, job, host, backup or data-freshness monitoring.

Sitewatch owns public endpoint targets, active measurement, cadence/retries,
native Application Insights availability results and operational alerts.
Status consumes those results; it must not run workload probes or a monitoring
sidecar, including to avoid monitoring cost. Status owns public aggregation,
history, incidents/notices and presentation, not strategic monitoring policy.

The corrected expansion preserves all 31 distinct public inputs (33 brand
projections). Sitewatch reuses ten existing measurements and adds 21 reviewed
baselines to its existing 14 checks. Existing checks retain their request budgets;
20 new baselines run every 300 seconds and Server Events every 60 seconds, with
zero retries, headers-only completion and no redirect following. The existing
three regional Flex Consumption apps and telemetry resources are reused, with
no always-ready capacity. New baseline results route once to the existing
primary Sitewatch App Insights resource; 21 availability metric alerts retain
strategic action-group routing.

Do not probe paid provider lookups, perform real
business transactions, call forum task runners, or wake auto-pausing databases
merely to populate a green status. Authentication redirects only establish that
the public route responds; static statistics and CDN health endpoints do not prove
updater freshness or asset completeness.

Repair existing alerts before adding new ones. Scheduled jobs use
`Audit:JobCompleted` / `Audit:JobFailed` and
`customDimensions["Audit.SourceComponent"]`; scope to the workload role, use
actual schedules and handle missing successful completions explicitly. Elapsed
age is `now() - LastSuccess`, not a reversed `datetime_diff`. Sampled request
failure totals use `sum(itemCount)`, a metric measure column and `Total`
aggregation, not the number of summary rows. Preserve existing human and private
evidence routes, resource identities, evaluation frequency and alert-series count
when fixing those contracts.

The legacy Portal Sync import-job rule is intentionally retained under its
existing Terraform/Azure identity and reused for player-tag reconciliation and
rotation cleanup. This avoids creating additional alert resources or dimension
series. Weekly completion freshness requires separate durable state or a longer
supported query window and is not provided by that rule; weekly failures are
still covered by the existing job-failure alert.

The authorised correction has a US$15/month incremental normal-operation planning
allowance, not a hard cap or a zero-cost guarantee. No new workspace, compute,
paid Standard web test or business-transaction canary is included. Native SDK
availability results still incur telemetry ingestion; Flex Consumption executions
and new metric-alert series also require cost accounting. Changes beyond the
reviewed coverage, cadence and alert series require another cost review rather
than moving collection back into status.

Compare complete state-backed plans for both environments before applying.
This migration's production plan is 21 alert additions and three existing app
configuration updates, with no destruction. Previously repaired Portal Sync and
Server Events alerts remain in place. Compare actual ingestion/execution/alert
usage against the baseline and allowance; request counts do not guarantee a bill.

## Status consumption boundary

Producer and consumer mirror versioned telemetry and binding fixtures, including
site/component/check identity, resource aliases, expected regions and cadence.
Production Sitewatch input validation rejects removal or drift of a consumed
binding; status catalogue tests enforce matching references. Deploy the producer
first and prove fresh measurements in every expected region before cutover.

The independent status consumer uses a dedicated certificate-authenticated Entra
reader with Monitoring Reader on exact Application Insights resources. It has no
directory API permissions, workload write access or deployment credentials.
The existing platform-workloads OIDC identity rotates its certificate through
Key Vault; private keys never enter Terraform state or the database container.

Status queries latest native measurements per identity/region with `arg_max`,
never a success average that hides a fresh regional outage. Explicit owning-site
filters and shared canonical references preserve brand isolation. Its background
worker writes cached observations; publication/public reads never await Azure,
GitHub or workload endpoints. Failed collection retains original timestamps and
ages to unknown. Durable cursors prevent repolls/restarts from inflating history.
The consumer's `--refresh-monitoring` preflight rejects incomplete fresh regional
coverage; real failed checks are valid observations, never fabricated green.

## Private status evidence

The dedicated global `status-evidence-prd` group sends the common alert schema
only to `https://mxstatus.io/api/integrations/azure`. Its secure webhook uses the
separate status-service identity from `platform-workloads.status_service_identity`,
not the deployment identity. That contract's `application_id` is the application
registration object ID; the client ID forms its `api://` identifier URI.
The approved Azure Monitor sender has only `Status.Ingest`, not publishing rights.
The group contains no email, SMS, push, or voice receivers.

Activate and verify the public HTTPS endpoint before creating this group: Azure
can reject an unresolved webhook hostname with `WebhookServiceUriBlocked`.
Create the group before separately planning subscription wiring against it.
The `terraform-sub/status_evidence.tf` wiring is Production-only and adds three
resources to each managed subscription's existing alerts resource group:

- A global Service Health rule covering all services, locations and event types.
- A global Resource Health rule without previous/current-state restrictions,
  including recovery transitions.
- An always-active AddActionGroups processing rule for Metric/Log signals, both
  Fired and Resolved, without replacing existing alert actions.

Service Health requires direct action-group routing and a global group; alert
processing rules do not affect it. Existing human-facing groups and health-rule
filters remain unchanged. Existing suppression rules retain precedence over the
additive processing rule, and processing-rule changes can take up to 30 minutes
to propagate. Development creates none of these resources.

Test only this dedicated group's secure webhook after the public HTTPS route is
ready. Verify the received event in private evidence and confirm no public
incident was created. Evidence is retained privately for operator review; all
public incident publication remains an explicit operator action.
The main-only **Verify Status Evidence** workflow reads the existing dedicated
group and refuses non-webhook receivers, a changed URL or tenant, and disabled
Entra/common-schema settings. It sends one native Service Health test through
the `2023-01-01` action-group `createNotifications` API and checks the individual
secure-webhook result, not just overall test completion. It uploads no receiver
configuration or token artifacts. A successful workflow still requires checking
the application's private evidence and unchanged public incident count.
Secure-webhook delivery is metered, so do not describe it as unlimited free
notifications. This integration adds no compute, log-ingestion service, or new
metric/log alert rules.
