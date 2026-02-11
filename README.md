# Platform Monitoring
[![Code Quality](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/codequality.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/codequality.yml)
[![Pull Request Validation](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/pull-request-validation.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/pull-request-validation.yml)
[![Feature Development](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/feature-development.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/feature-development.yml)
[![Release to Production](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/release-to-production.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/release-to-production.yml)
[![Destroy Environment](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/destroy-environment.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/destroy-environment.yml)
[![Dependabot Automerge](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/dependabot-automerge.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/dependabot-automerge.yml)
[![Copilot Setup Steps](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/copilot-setup-steps.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/copilot-setup-steps.yml)

## Documentation
- [Manual Steps](/docs/manual-steps.md) - Secrets to seed alert contact details
- [Consuming Platform Monitoring](/docs/consuming-platform-monitoring.md) - How downstream workloads read shared monitoring outputs

## Overview
Terraform builds a shared Azure Monitor stack for the platform: a central Log Analytics workspace, severity-based action groups, and a Key Vault seeded with placeholder alert contacts. Resource groups and backend settings are sourced from the platform-workloads remote state so environments stay consistent, and state backends live under terraform/backends for dev and prd. Outputs expose workspace and action group identifiers for downstream workloads to attach diagnostics and alert rules without duplicating infrastructure.

## Contributing
Please read the [contributing](CONTRIBUTING.md) guidance; this is a learning and development project.

## Security
Please read the [security](SECURITY.md) guidance; I am always open to security feedback through email or opening an issue.
