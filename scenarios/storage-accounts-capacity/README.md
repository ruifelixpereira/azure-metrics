# Collect Storage Used Capacity

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
