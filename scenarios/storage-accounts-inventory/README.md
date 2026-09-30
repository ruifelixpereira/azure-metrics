# Storage account inventory

[storage-accounts.kql](storage-accounts.kql) lists storage accounts and their configuration, including location, kind, SKU, access tier, and hierarchical namespace support. Run it using the same portal steps, or with Azure CLI:

```bash
az graph query \
  --graph-query "$(cat storage-accounts.kql)" \
  --first 1000 \
  --output table
```

Resource Graph limits each response page. Increase `--first` as needed within the service limit, or use Azure CLI pagination when the environment contains more resources than one response can return.