# AGENTS.md - platform-monitoring

This repository owns shared Azure Monitor infrastructure and subscription-level health alerts. It has two independent Terraform roots: `terraform/` for the shared monitoring stack and `terraform-sub/` for per-subscription alert wiring.

## Key locations

- `terraform/` - Log Analytics, Key Vault, action groups, workbooks, and shared outputs.
- `terraform-sub/` - Resource Health and Service Health alerts for individual subscriptions.
- `terraform/remote_state.tf` - `platform-workloads` state contract.
- `docs/manual-steps.md` - alert contact secret seeding and rotation.
- `docs/consuming-platform-monitoring.md` - downstream output contract.

## Validation

For documentation or Copilot-configuration-only changes:

```pwsh
git diff --check
```

For Terraform changes, validate each affected root:

```pwsh
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false -lockfile=readonly
terraform -chdir=terraform validate
terraform -chdir=terraform-sub fmt -check -recursive
terraform -chdir=terraform-sub init -backend=false -lockfile=readonly
terraform -chdir=terraform-sub validate
```

Run state-backed plans only for infrastructure-affecting changes, using matching `dev` or `prd` backend and tfvars files.

## Guardrails

- This is the strategic monitoring owner. Workloads own instrumentation and
  workload-specific alert definitions using shared infrastructure; Sitewatch owns
  public availability collection. Status owns read-only consumption, public
  aggregation/history and operator publishing, never workload probes or a
  monitoring sidecar. Cost constraints do not override these boundaries.
- Keep producer/consumer telemetry and binding contracts aligned, retain stale/
  unknown semantics and verify regional coverage before status cutover. Reader
  identities must use exact resource scopes, not deployment credentials.
- Keep the shared stack and subscription-alert stack boundaries distinct.
- Preserve provider aliases and the `platform-workloads` remote-state/output contracts.
- Key Vault uses RBAC and purge protection; alert contact values are manually managed secrets.
- Action-group or alert changes can alter tenant-wide incident routing.
- Use OIDC or managed identity; never add credentials to Terraform or documentation.
- Commit each root's `.terraform-version` and `.terraform.lock.hcl`. Select the exact root CLI pin before invoking Terraform; normal initialization uses `-lockfile=readonly`. Regenerate provider selections only in a reviewed dependency-update PR; never commit state, plans, or `.terraform/`.

See [README.md](README.md), [docs/manual-steps.md](docs/manual-steps.md), and [docs/consuming-platform-monitoring.md](docs/consuming-platform-monitoring.md).
