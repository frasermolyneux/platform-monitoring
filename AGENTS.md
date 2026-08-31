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
terraform -chdir=terraform init -backend=false -upgrade
terraform -chdir=terraform validate
terraform -chdir=terraform-sub fmt -check -recursive
terraform -chdir=terraform-sub init -backend=false -upgrade
terraform -chdir=terraform-sub validate
```

Run state-backed plans only for infrastructure-affecting changes, using matching `dev` or `prd` backend and tfvars files.

## Guardrails

- Keep the shared stack and subscription-alert stack boundaries distinct.
- Preserve provider aliases and the `platform-workloads` remote-state/output contracts.
- Key Vault uses RBAC and purge protection; alert contact values are manually managed secrets.
- Action-group or alert changes can alter tenant-wide incident routing.
- Use OIDC or managed identity; never add credentials to Terraform or documentation.
- `.terraform.lock.hcl` is local generated state, ignored, and not committed.

See [README.md](README.md), [docs/manual-steps.md](docs/manual-steps.md), and [docs/consuming-platform-monitoring.md](docs/consuming-platform-monitoring.md).
