# Copilot Instructions

> Shared conventions: see [`.github-copilot/.github/instructions/terraform.instructions.md`](../../.github-copilot/.github/instructions/terraform.instructions.md) (sibling repo) for the standard Terraform layout, providers, remote-state pattern, validation commands, and CI/CD workflows.

## Project overview
Terraform-managed repository that builds shared Azure Monitor primitives. Two Terraform roots exist: `terraform/` (core monitoring stack) and `terraform-sub/` (subscription-level alert wiring).

## Repository specifics
- `terraform/` — Core stack: Log Analytics workspace, Key Vault for alert contacts, severity-based action groups (P0–P4), and workbook JSON templates.
- `terraform-sub/` — Subscription alerts: Resource Health and Service Health activity log alerts wired to shared action groups via a provider alias.
- `src/monitoring-func/` — .NET Azure Function project (supporting code).
- `docs/` — Documentation on manual steps and consuming platform-monitoring outputs.
- `params/` — Platform and service parameter files for production.

## Stack-specific conventions
- Key Vault uses RBAC + purge protection; `alert-email` and `alert-phone` secrets require manual rotation (see `docs/manual-steps.md`).
- Outputs expose Log Analytics workspace and action group identifiers for downstream consumers.
