# Platform Monitoring

| Stage                   | Status                                                                                                                                                                                                                                           |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| DevOps Secure Scanning  | [![DevOps Secure Scanning](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/devops-secure-scanning.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/devops-secure-scanning.yml)    |
| Feature Development     | [![Feature Development](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/feature-development.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/feature-development.yml)             |
| Pull Request Validation | [![Pull Request Validation](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/pull-request-validation.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/pull-request-validation.yml) |
| Release to Production   | [![Release to Production](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/release-to-production.yml/badge.svg)](https://github.com/frasermolyneux/platform-monitoring/actions/workflows/release-to-production.yml)       |

---

## Documentation

* [manual-steps](/docs/manual-steps.md)

---

## Overview

This repository contains the resource configuration and associated Azure DevOps pipelines for monitoring related resources; this is primarily focused on workloads that are *not* on the Azure platform.

---

## Related Projects

* [frasermolyneux/azure-landing-zones](https://github.com/frasermolyneux/azure-landing-zones) - The deploy service principal is managed by this project, as is the workload subscription.

---

## Solution

The solution will deploy the following resources:

* Application Insights
* Web Availability Tests
* Action Groups / Alerting

---

## Azure Pipelines

The `one-pipeline` is within the `.azure-pipelines` folder and output is visible on the [frasermolyneux/Personal-Public](https://dev.azure.com/frasermolyneux/Personal-Public/_build?definitionId=174) Azure DevOps project.

---

## Contributing

Please read the [contributing](CONTRIBUTING.md) guidance; this is a learning and development project.

---

## Security

Please read the [security](SECURITY.md) guidance; I am always open to security feedback through email or opening an issue.
