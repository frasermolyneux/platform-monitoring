# Copilot Instructions

## Project overview
Terraform-managed repository that builds shared Azure Monitor primitives. Two Terraform roots exist: `terraform/` (core monitoring stack) and `terraform-sub/` (subscription-level alert wiring). Remote state from platform-workloads supplies resource groups; identities authenticate via AzureAD/OIDC (no client secrets).

## Repository layout
- `terraform/` — Core stack: Log Analytics workspace, Key Vault for alert contacts, severity-based action groups (P0–P4), and workbook JSON templates.
- `terraform-sub/` — Subscription alerts: Resource Health and Service Health activity log alerts wired to shared action groups via a provider alias.
- `src/monitoring-func/` — .NET Azure Function project (supporting code).
- `docs/` — Documentation on manual steps and consuming platform-monitoring outputs.
- `params/` — Platform and service parameter files for production.
- `.github/workflows/` — CI/CD: `build-and-test`, `pr-verify`, `deploy-dev`, `deploy-prd`, `destroy-environment`, `codequality`, `dependabot-automerge`, `copilot-setup-steps`.

## Terraform conventions
- Provider: `azurerm` >= 4.59, AzureAD storage auth; workspace subscription set via `subscription_id` variable.
- Backend: `azurerm` backend with per-env config in `backends/` directories; init with `-backend-config=backends/<env>.backend.hcl`, plan with `-var-file=tfvars/<env>.tfvars`.
- Resource groups come from platform-workloads remote state (`remote_state.tf`, `locals.tf`); tags and workload names originate in tfvars.
- Key Vault uses RBAC + purge protection; `alert-email` and `alert-phone` secrets require manual rotation (see `docs/manual-steps.md`).
- Outputs expose Log Analytics workspace and action group identifiers for downstream consumers.

## Code style and practices
- Keep Terraform files focused: one resource type per file, use `data.*` prefix for data-source files.
- Use `locals` for computed values; avoid hardcoding resource names.
- All infrastructure changes flow through GitHub Actions workflows—never apply directly from a local machine.
- When adding new resources, include appropriate outputs so downstream workloads can consume them via remote state.

## Testing and validation
- Run `terraform fmt -check` and `terraform validate` before committing.
- The `pr-verify` workflow runs plan against dev; `build-and-test` runs on push to main.
- `codequality` runs weekly scheduled checks.
