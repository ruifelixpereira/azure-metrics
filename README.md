# Azure Metrics Collection

This repository contains several scenarios for collecting Azure resource data and capacity metrics.

## Scenarios

| Scenario | Description |
| --- | --- |
| [Storage accounts inventory](scenarios/storage-accounts-inventory/README.md) | Lists storage accounts and key configuration details, including location, SKU, access tier, and hierarchical namespace support. |
| [Storage accounts used capacity](scenarios/storage-accounts-capacity/README.md) | Collects the latest used-capacity metric for storage accounts across accessible Azure subscriptions and exports the results to CSV. |
| [SQL configured capacity](scenarios/sql-used-capacity/README.md) | Reports Azure SQL databases and managed instances with their service tier, vCores, and configured storage capacity. |
| [Private endpoints usage](scenarios/private-endpoints-usage/README.md) | Checks private endpoint usage during the last 30 days and exports the results to CSV. |

## Patterns

The scenarios in this repository for collecting Azure resource data and capacity metrics mostly follow 2 patterns:

1. Run KQL queries against Azure Resource Graph for resource inventory and configured capacity.
2. Run a shell script that calls Azure Monitor Metrics and generates a CSV report of storage usage.

## Prerequisites

- Access to the Azure subscriptions and resources being queried.
- The [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) for command-line collection.
- The Azure CLI Resource Graph extension for running KQL from the command line.
- `bash`, `jq`, and `awk` for the storage capacity script.
- Azure permissions to read resources and Azure Monitor metrics. The script checks every enabled subscription visible to the signed-in account and skips subscriptions it cannot access.

Install the Resource Graph extension with:

```bash
az extension add --name resource-graph
```

Authenticate before using the CLI:

```bash
az login
```
