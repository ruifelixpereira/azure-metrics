# Azure Metrics Collection

This repository contains two approaches for collecting Azure resource data and capacity metrics:

1. Run KQL queries against Azure Resource Graph for resource inventory and configured capacity.
2. Run a shell script that calls Azure Monitor Metrics and generates a CSV report of storage usage.

## Prerequisites

- Access to the Azure subscriptions and resources being queried.
- The [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) for command-line collection.
- The Azure CLI Resource Graph extension for running KQL from the command line:

	```bash
	az extension add --name resource-graph
	```

- `bash`, `jq`, and `awk` for the storage capacity script.
- Azure permissions to read resources and Azure Monitor metrics. The script checks every enabled subscription visible to the signed-in account and skips subscriptions it cannot access.

Authenticate before using the CLI:

```bash
az login
```

## Scenario 1: Query Azure Resource Graph

Azure Resource Graph provides resource inventory and configuration data across subscriptions. These queries do not call Azure Monitor and therefore report resource properties rather than live utilization metrics.

### SQL configured capacity

[sql-used-capacity.kql](sql-used-capacity.kql) lists Azure SQL databases and SQL managed instances, including subscription, resource group, SKU, service tier, vCores, and configured storage capacity.

To run it in the Azure portal:

1. Open **Azure Resource Graph Explorer**.
2. Select the required directory and subscription scope.
3. Paste the contents of [sql-used-capacity.kql](sql-used-capacity.kql) into the query editor.
4. Select **Run query** and optionally download the results as CSV.

To run the same query with Azure CLI:

```bash
az graph query \
	--graph-query "$(cat sql-used-capacity.kql)" \
	--first 1000 \
	--output table
```

Use `--subscriptions` to restrict the query to specific subscriptions:

```bash
az graph query \
	--graph-query "$(cat sql-used-capacity.kql)" \
	--subscriptions <subscription-id> \
	--first 1000 \
	--output table
```

### Storage account inventory

[storage-accounts.kql](storage-accounts.kql) lists storage accounts and their configuration, including location, kind, SKU, access tier, and hierarchical namespace support. Run it using the same portal steps, or with Azure CLI:

```bash
az graph query \
	--graph-query "$(cat storage-accounts.kql)" \
	--first 1000 \
	--output table
```

Resource Graph limits each response page. Increase `--first` as needed within the service limit, or use Azure CLI pagination when the environment contains more resources than one response can return.

## Scenario 2: Collect Storage Used Capacity

Azure Resource Graph exposes storage account configuration but not current used capacity. [storage-capacity.sh](storage-capacity.sh) enumerates storage accounts and calls Azure Monitor Metrics for the `UsedCapacity` metric of each account.

The script:

- Retrieves all subscriptions visible to the signed-in Azure account.
- Processes enabled and accessible subscriptions.
- Lists the storage accounts in each subscription.
- Requests the latest hourly average for the `UsedCapacity` metric.
- Converts used bytes to tebibytes using $1\ \text{TiB} = 2^{40}\ \text{bytes}$.
- Writes the combined results to `storage_inventory.csv` in the current directory.

Run it from the repository directory:

```bash
chmod +x storage-capacity.sh
./storage-capacity.sh
```

Alternatively, run it without changing file permissions:

```bash
bash storage-capacity.sh
```

The generated CSV contains these columns:

| Column | Description |
| --- | --- |
| `SubscriptionName` | Subscription display name |
| `SubscriptionId` | Subscription ID |
| `ResourceGroup` | Resource group containing the storage account |
| `StorageAccount` | Storage account name |
| `Location` | Azure region |
| `SKU` | Storage account SKU and replication option |
| `Kind` | Storage account kind |
| `HnsEnabled` | Whether hierarchical namespace is enabled |
| `UsedBytes` | Latest reported used capacity in bytes |
| `UsedTB` | Used capacity converted to TiB and rounded to two decimal places |

If Azure Monitor does not return a `UsedCapacity` value, the script records `0` for that storage account. Existing `storage_inventory.csv` content is replaced each time the script starts.
