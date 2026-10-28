# Manual Steps

After the monitoring stack creates the Key Vault, replace the placeholder values
for `alert-email` and `alert-phone` with the real notification contacts. Terraform
intentionally ignores subsequent value changes so contact rotation remains a
manual secret-management operation.

Do not add workload application secrets to this Key Vault. Runtime secrets such
as Invision task keys belong in the workload runtime Key Vault managed by
`platform-baremetal`.

## Shared Smart Detection handover

The shared subscription's auto-created Smart Detection group was located in
Travel Itinerary's resource group but is also used by surviving workloads.
Never delete that group while any reference remains.

The production-only `shared_smart_detection` resources provide a protected
replacement in the **same subscription**, preserving the original enabled state,
short name, Monitoring Contributor/Reader receivers and common-alert-schema
settings. No contact secrets, new notification destinations or telemetry are added.

Review the complete Production plan and apply the core stack first. After Trip
and Talk's legacy alerts are retired, dispatch **Shared Smart Detection Handover**
on reviewed main. It rejects incomplete/unknown references and recipient drift,
updates only CraftPledge, Geo Location and Platform Notifications group IDs,
and verifies every other alert property unchanged. Retries preserve completed
updates and the old group. Full rule bodies are retained because the documented
2021-04-01 resource contract uses complete resource updates; do not make concurrent
changes to shared-subscription notification routing during the bounded handover
and retirement window. Cross-resource Azure updates are not atomic.

Only after all references clear, explicitly dispatch **Retire Unreferenced Travel
Monitoring Group**. This separate operation uses the monitoring identity's complete
subscription visibility, rechecks all surviving routes, the replacement receiver
contract, zero references and the exact otherwise-empty Travel inventory before
deleting only the old group. Travel's existing guarded destroy can then retry its
empty-resource-group assertion before catalog decommissioning. Workload alert
definitions and instrumentation remain with their existing owners.

The read-only PR audit handles both migration states. Once the old group is
absent, it validates the replacement recipients, all three surviving routes and
zero old references without reading Travel's retired resource group. Authored
guard failures identify the failed prerequisite; raw Azure diagnostics and
unexpected response content remain suppressed.

Resource Graph is discovery evidence, not the sole deletion gate. Direct ARM
subscription listings additionally inspect Smart Detection, metric, scheduled
query and activity-log alerts, alert processing rules, Prometheus rule groups
and consumption budgets. Both incomplete pages and live references block
retirement, including when Resource Graph has not indexed a recent change.

The [2021-04-01 detector configuration](https://learn.microsoft.com/en-us/azure/templates/microsoft.alertsmanagement/2021-04-01/smartdetectoralertrules#detector)
contains writable `id` and `parameters`. GET additionally returns service-owned
detector metadata and can add an empty `parameterDefinitions` after PUT. The
handover excludes only those known read-only metadata fields from requests and
configuration comparison. All writable fields, including disabled state, custom
payloads, throttling and detector parameters, still verify exactly; unknown
detector fields stop for review.
