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
manual changes to these three rules during the bounded handover.

Only after all references clear, explicitly dispatch **Retire Unreferenced Travel
Monitoring Group**. This separate operation uses the monitoring identity's complete
subscription visibility, rechecks all surviving routes, the replacement receiver
contract, zero references and the exact otherwise-empty Travel inventory before
deleting only the old group. Travel's existing guarded destroy can then retry its
empty-resource-group assertion before catalog decommissioning. Workload alert
definitions and instrumentation remain with their existing owners.
