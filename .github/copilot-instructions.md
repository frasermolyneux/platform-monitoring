# Copilot Instructions

## Repository purpose

`platform-monitoring` owns the shared Azure Monitor foundation and subscription health alerts. Downstream repositories consume its Log Analytics workspace and action-group outputs.

## Terraform layout and boundaries

- `terraform/` is the core stack: Log Analytics, alert-contact Key Vault, P0-P4 action groups, workbooks, and shared outputs.
- `terraform-sub/` is a separate root for per-subscription Resource Health and Service Health alerts.
- Both roots have `dev` and `prd` backend/tfvars pairs.
- `terraform/remote_state.tf` reads environment resource groups from `platform-workloads`.
- `terraform-sub` uses an `azurerm.action_group` provider alias to reference shared action groups across subscriptions.

Both roots require Terraform `>= 1.15.6` and AzureRM `~> 5.2.0`. Preserve provider aliases and constraints.

Key Vault uses RBAC and purge protection. Alert email and phone values are operational secrets seeded and rotated through the process in `docs/manual-steps.md`; do not put their values in source control.

## Validation and planning

Documentation and Copilot configuration changes require `git diff --check` and link review; they do not require a Terraform plan.

Validate every affected Terraform root:

```pwsh
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false -upgrade
terraform -chdir=terraform validate
terraform -chdir=terraform-sub fmt -check -recursive
terraform -chdir=terraform-sub init -backend=false -upgrade
terraform -chdir=terraform-sub validate
```

For infrastructure changes, initialize the matching environment before planning the core stack:

```pwsh
terraform -chdir=terraform init -reconfigure -backend-config=backends/dev.backend.hcl
terraform -chdir=terraform plan -var-file=tfvars/dev.tfvars
```

Use both `prd` files for production. Subscription-root plans also require the matching backend/tfvars plus the subscription name, ID, monthly budget, and subscription-specific backend key; obtain those values from the core stack outputs rather than inventing them.

## Safety

- Preserve remote-state and published output shapes used by downstream workloads.
- Do not collapse the two Terraform roots or mix their state.
- Treat action-group, alert, retention, diagnostic, and Key Vault changes as broad operational-impact changes.
- Do not apply, import, move, or remove state unless explicitly requested.
- Use OIDC or managed identity; never add client secrets, contact values, tokens, or connection strings.
- `.terraform.lock.hcl` is generated locally, ignored, and never committed.

See [docs/manual-steps.md](../docs/manual-steps.md) and [docs/consuming-platform-monitoring.md](../docs/consuming-platform-monitoring.md).
