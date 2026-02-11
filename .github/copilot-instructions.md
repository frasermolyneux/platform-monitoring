# Copilot Instructions

## Purpose & layout
- Terraform-only repo that builds shared monitoring primitives. Core stack lives in [terraform](terraform) (Log Analytics workspace, Key Vault for alert contacts, severity-based action groups, workbooks) and subscription-level alert wiring lives in [terraform-sub](terraform-sub).
- Remote state from platform-workloads supplies resource group/backends; identities authenticate with AzureAD/OIDC (no client secrets).

## Core stack (terraform/)
- Providers: azurerm >= 4.59 with AzureAD storage auth; workspace subscription is `subscription_id` ([terraform/providers.tf](terraform/providers.tf#L1)).
- State/backend: azurerm backend configured via [terraform/backends](terraform/backends); choose `dev.backend.hcl` or `prd.backend.hcl` then apply matching `tfvars` file (e.g., `terraform -chdir=terraform init -backend-config=backends/dev.backend.hcl` then `plan -var-file=tfvars/dev.tfvars`).
- Resource group comes from platform-workloads remote state ([terraform/remote_state.tf](terraform/remote_state.tf#L1), [terraform/locals.tf](terraform/locals.tf#L1)); tags and workload names originate in tfvars.
- Log Analytics workspace defined in [terraform/log_analytics.tf](terraform/log_analytics.tf#L1); outputs surface name/id/workspace_id for consumers ([terraform/outputs.tf](terraform/outputs.tf#L7)).
- Action groups for severities P0–P4 live in [terraform/monitor_action_groups.tf](terraform/monitor_action_groups.tf#L1); production adds email/SMS/app push recipients from Key Vault secrets ([terraform/key_vault_secrets.tf](terraform/key_vault_secrets.tf#L1)).
- Key Vault (`kv-<random>-<location>`) holds alert contact placeholders and uses RBAC + purge protection ([terraform/key_vault.tf](terraform/key_vault.tf#L1)). Manual rotation of `alert-email`/`alert-phone` is required—see [docs/manual-steps.md](docs/manual-steps.md).
- Workbooks are JSON under [terraform/workbooks](terraform/workbooks) for manual import if needed.

## Subscription alerts (terraform-sub/)
- Adds activity log alerts per subscription for Resource Health and Service Health, pushing to shared action groups ([terraform-sub/resource_health_alerts.tf](terraform-sub/resource_health_alerts.tf#L1), [terraform-sub/service_health_alerts.tf](terraform-sub/service_health_alerts.tf#L1)).
- Uses provider alias `action_group` to read action groups from the main monitoring subscription ([terraform-sub/providers.tf](terraform-sub/providers.tf#L15), [terraform-sub/data.monitor_action_groups.tf](terraform-sub/data.monitor_action_groups.tf#L1)).
- Creates a dedicated RG `rg-platform-alerts-<env>-<location>` for alert rules ([terraform-sub/resource_group.tf](terraform-sub/resource_group.tf#L1)).
- Run with per-env tfvars in [terraform-sub/tfvars](terraform-sub/tfvars) after backend init (e.g., `terraform -chdir=terraform-sub init -backend-config=backends/dev.backend.hcl` then `plan -var-file=tfvars/dev.tfvars`).

## Inputs & outputs
- Core tfvars supply `subscription_id`, map of target `subscriptions` (exposed via output), tags, and `platform_workloads_state` backend coordinates for resource group discovery. Keep OIDC-enabled storage access for state reads.
- Subscription tfvars require the monitored `subscription_id`/name plus `action_group_subscription_id` pointing at the monitoring subscription.

## CI/CD
- GitHub Actions: `feature-development` and `pull-request-validation` handle PR validation; `release-to-production` promotes dev/prd; `destroy-environment` tears down; maintenance via `dependabot-automerge` and `copilot-setup-steps`. Badges in README track status.

## Quickstart
- Core stack: `terraform -chdir=terraform init -backend-config=backends/<env>.backend.hcl`; `terraform -chdir=terraform plan -var-file=tfvars/<env>.tfvars`; apply in release workflow only.
- Subscription alerts: same pattern under `terraform-sub/`; ensure action groups already exist in the monitoring subscription.
