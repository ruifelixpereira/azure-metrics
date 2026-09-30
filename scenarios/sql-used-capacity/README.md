# SQL configured capacity

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
