---
name: "Align Platform Monitoring Consumers"
description: "Guide Copilot to align workspace projects that consume platform-monitoring state and shared resources."
argument-hint: "Provide workspace root and target projects."
agent: "copilot-chat"
model: "gpt-5.1-codex-max"
tools: ["file_search", "read_file", "apply_patch", "run_in_terminal"]
---
Intent: Ensure all workspace projects that consume platform-monitoring use the documented remote state, permissions, and alert/log wiring patterns.

Inputs:
- {{workspace_root}}: absolute or VS Code `${workspaceFolder}` for the target repo.
- {{target_projects}}: list of projects/workloads to audit (e.g., `platform-sitewatch-func`).
- {{environments}}: environments to align; defaults to `[dev, prd]` if unspecified.

Guardrails:
1. Default shell is `pwsh.exe`; never run destructive commands (`git reset --hard`, `git clean -fd`).
2. Use the documented consumption pattern in [docs/consuming-platform-monitoring.md](docs/consuming-platform-monitoring.md) for remote state, action groups, and diagnostics; flag any deviations.
3. When reading platform-monitoring state, require `Storage Blob Data Reader` on the state account per the Access section; confirm roles come from platform-workloads `requires_terraform_state_access` JSON (see [platform-workloads](https://github.com/frasermolyneux/platform-workloads)).
4. Mirror the parameterized backend pattern used in [platform-sitewatch-func/terraform/remote_state.tf](../platform-sitewatch-func/terraform/remote_state.tf) and its variable contract in [platform-sitewatch-func/terraform/variables.tf](../platform-sitewatch-func/terraform/variables.tf) when updating consumers.
5. Reference the correct backend files for each environment ([terraform/backends/dev.backend.hcl](terraform/backends/dev.backend.hcl) and [terraform/backends/prd.backend.hcl](terraform/backends/prd.backend.hcl)) and ensure `use_oidc` remains true; process all environments by default.
6. Run only repository-approved tasks or `terraform fmt`/`terraform plan` as appropriate; avoid unapproved tooling. Mention #tool:run_task or #tool:run_in_terminal when execution is needed.
7. Cite official VS Code prompt and custom instruction docs when explaining adherence: [prompt files](https://code.visualstudio.com/docs/copilot/customization/prompt-files) and [custom instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions).

Validation:
- For each target project and each environment (default dev + prd), note whether it already uses `terraform_remote_state platform_monitoring` with the documented backend/outputs; provide file links.
- Confirm the identity used has remote state access and required monitoring roles; note source (platform-workloads JSON or manual assignment).
- Summarize any changes made or required; if changes applied, summarize diff paths and recommend running `terraform plan` for the affected project.

Example:
```hcl
variable "platform_monitoring_state" { /* ... see docs/consuming-platform-monitoring.md */ }

data "terraform_remote_state" "platform_monitoring" {
  backend = "azurerm"
  config  = var.platform_monitoring_state
}
```

Checklist:
- Frontmatter present with name/description/agent/model/tools.
- Inputs captured and used.
- Guardrails enforced and cite required files/tools.
- Validation steps included.
- VS Code and non-destructive shell reminders present.
