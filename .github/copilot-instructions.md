# Copilot Instructions

- Purpose: monitor mostly non-Azure workloads via a .NET 9 isolated Azure Function that pings external health endpoints and forwards availability telemetry to multiple Application Insights instances. IaC lives in terraform/; a second stack in terraform-sub/ manages subscription-level alerts.
- Core runtime files: host wiring in [src/monitoring-func/Program.cs](../src/monitoring-func/Program.cs); HTTP health endpoint in [src/monitoring-func/HealthCheck.cs](../src/monitoring-func/HealthCheck.cs); timer-driven availability checks in [src/monitoring-func/ExternalHealthCheck.cs](../src/monitoring-func/ExternalHealthCheck.cs); telemetry role stamping in [src/monitoring-func/TelemetryInitializer.cs](../src/monitoring-func/TelemetryInitializer.cs).
- Health endpoint: anonymous GET at /api/health returns the aggregate HealthStatus enum text from `HealthCheckService`; log level tuned to Warning in [src/monitoring-func/host.json](../src/monitoring-func/host.json).
- Availability timer: runs every 30s ("0,30 * * * * *"); reads JSON `test_config` setting into a list of [src/monitoring-func/TestConfig.cs](../src/monitoring-func/TestConfig.cs) objects. Each item supplies `app`, `app_insights`, `uri`. URIs can contain %TOKEN% placeholders resolved from IConfiguration.
- App Insights fan-out: for each `app_insights` value, ExternalHealthCheck builds a per-target TelemetryClient using configuration key `<app_insights>_appinsights_connection_string` (lower-cased). Terraform populates `default/portal/geolocation` connection strings; match new keys to this naming pattern.
- Availability telemetry: IDs are Activity-based; run location pulled from REGION_NAME env (falls back to "Unknown"). Exceptions and availability events are excluded from sampling via host.json samplingSettings.
- HTTP probe logic: HttpClient per invocation, 10s timeout, Polly retry 3x with exponential backoff on non-2xx/timeout/HttpRequestException. On retry logs exception and response content; failure throws to mark telemetry Success=false and set Message.
- Build/runtime: .NET 9, Azure Functions v4 isolated. Project file is [src/monitoring-func/monitoring-func.csproj](../src/monitoring-func/monitoring-func.csproj) with UserSecrets enabled; OutputType Exe.
- Local tasks: VS Code task `build (functions)` runs `dotnet build` in src/monitoring-func (depends on `clean (functions)`); `func: 4` runs `func host start` from bin/Debug/net9.0 after build. Commands if run manually:
  ```
  dotnet clean src/monitoring-func
  dotnet build src/monitoring-func
  func host start --script-root src/monitoring-func/bin/Debug/net9.0
  ```
- Configuration expectations locally: supply `test_config` JSON plus `<key>_appinsights_connection_string` settings (default/portal/geolocation) via local.settings.json or user secrets; timer trigger still fires unless disabled via Azure Functions Core Tools flags.
- Telemetry defaults: TelemetryInitializer sets Cloud.RoleName to "Monitoring FuncApp"; ApplicationInsightsAgent_EXTENSION_VERSION set to ~3 in app settings via Terraform; profiler/diagnostic extension settings already included.
- Terraform workflows (env-specific):
  - Init: `terraform -chdir=terraform init -backend-config=backends/dev.backend.hcl` (or prd backend).
  - Plan/apply: `terraform -chdir=terraform plan -var-file=tfvars/dev.tfvars` then `apply`.
  - terraform-sub/ stack: same pattern using its own backend and tfvars for subscription-level health alerts.
- Terraform particulars: azurerm provider ~>4.55 with storage_use_azuread; function app deployed per location with consumption plan (Y1) and isolated runtime set use_dotnet_isolated_runtime=true, dotnet_version=9.0; app settings include `test_config` (jsonencoded var.availability_tests) and Key Vault secret reference for `xtremeidiots_forums_task_key`.
- State/backends: backends/*.backend.hcl include OIDC auth; tfvars/{dev,prd}.tfvars provide subscription IDs, App Insights references, availability test matrix, Log Analytics workspace, and tags. Update both stacks if adding environments.
- Manual prerequisites: before deployment add Key Vault secrets `alert-email`, `alert-phone`, and `xtremeidiots-task-key` (see [docs/manual-steps.md](../docs/manual-steps.md)).
- Patterns/conventions: prefer adding new availability targets by editing tfvars availability_tests; ensure `app_insights` matches locals.app_insights_map keys and that Terraform emits corresponding connection strings. URIs should expose a health endpoint returning HTTP 200.
- Monitoring/alerts: terraform/ includes monitor_action_groups.tf and monitor_metric_alerts.tf; workbooks JSONs live under terraform/workbooks/ and are deployed via IaC.
- Security defaults: function app disables public network access and FTPS, enforces TLS 1.2, sets https_only, uses system-assigned identity. Action groups and key vault wired through Terraform.
- Contribution reminders: README highlights this as a learning project; follow CONTRIBUTING.md/SECURITY.md norms in repo root.

If any section is unclear or missing important project knowledge, tell me which parts to refine.
