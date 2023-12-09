# Platform Monitoring

| Stage                  | Status                                                                                                                                                                                                                                                                                                                                                             |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| DevOps Secure Scanning | [![Build Status](https://dev.azure.com/frasermolyneux/Personal-Public/_apis/build/status%2Fplatform-monitoring.DevOpsSecureScanning?branchName=main)](https://dev.azure.com/frasermolyneux/Personal-Public/_build/latest?definitionId=207&branchName=main)                                                                                                         |
| Build                  | [![Build Status](https://dev.azure.com/frasermolyneux/Personal-Public/_apis/build/status%2Fplatform-monitoring.OnePipeline?repoName=frasermolyneux%2Fplatform-monitoring&branchName=main&stageName=build)](https://dev.azure.com/frasermolyneux/Personal-Public/_build/latest?definitionId=174&repoName=frasermolyneux%2Fplatform-monitoring&branchName=main)      |
| Release to Production  | [![Build Status](https://dev.azure.com/frasermolyneux/Personal-Public/_apis/build/status%2Fplatform-monitoring.OnePipeline?repoName=frasermolyneux%2Fplatform-monitoring&branchName=main&stageName=deploy_prd)](https://dev.azure.com/frasermolyneux/Personal-Public/_build/latest?definitionId=174&repoName=frasermolyneux%2Fplatform-monitoring&branchName=main) |

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
