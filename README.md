# Platform Monitoring

[![Build and Test](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/build-and-test.yml)
[![Code Quality](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/codequality.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/codequality.yml)
[![Copilot Setup Steps](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/copilot-setup-steps.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/copilot-setup-steps.yml)
[![Dependabot Auto-Merge](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/dependabot-automerge.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/dependabot-automerge.yml)
[![Deploy Dev](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/deploy-dev.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/deploy-dev.yml)
[![Deploy Prd](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/deploy-prd.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/deploy-prd.yml)
[![Destroy Environment](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/destroy-environment.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/destroy-environment.yml)
[![PR Verify](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/pr-verify.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/pr-verify.yml)

## Documentation

- [Manual Steps](/docs/manual-steps.md) - Secrets to seed alert contact details
- [Consuming Platform Monitoring](/docs/consuming-platform-monitoring.md) - How downstream workloads read shared monitoring outputs

## Overview

This repository contains Terraform configurations that build a shared Azure Monitor stack for the platform, including a central Log Analytics workspace, severity-based action groups (P0–P4), and a Key Vault seeded with placeholder alert contacts. Resource groups and backend settings are sourced from the platform-workloads remote state so environments stay consistent across dev and prd. A secondary Terraform root under `terraform-sub/` wires subscription-level Resource Health and Service Health alerts to the shared action groups. Outputs expose workspace and action group identifiers for downstream workloads to attach diagnostics and alert rules without duplicating infrastructure.

## Contributing

Please read the [contributing](CONTRIBUTING.md) guidance; this is a learning and development project.

## Security

Please read the [security](SECURITY.md) guidance; I am always open to security feedback through email or opening an issue.
