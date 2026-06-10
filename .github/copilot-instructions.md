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

## Org conventions via MCP (when available)

If a `frasermolyneux-copilot` MCP server is configured in your client (`.vscode/mcp.json`, the GitHub Copilot coding-agent MCP config at `.github/copilot/mcp_config.json`, or an equivalent stdio MCP wire-up), **prefer its tools** over your own assumptions when answering questions about org standards, branching, workflows, Terraform, .NET projects, Azure patterns, or shared library / platform consumption contracts. The tool surface is `list_instructions`, `get_instruction`, `search_instructions`, plus the matching `_prompts` and `_agents` equivalents (seven tools total). The catalog source-of-truth lives in `frasermolyneux/.github-copilot` — see `mcp-server/README.md` there for the tool contract.

This is **complementary** to the file-load model: if `./.github-copilot/` is checked out in the runner (per `copilot-setup-steps.yml`), continue to read those files directly. If both are available, prefer MCP for freshness. If no MCP server is configured in your client, treat this section as a no-op and fall back to the file paths above.