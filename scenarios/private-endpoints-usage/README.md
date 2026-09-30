# Check Private Endpoints Usage in the Last 30 days

The script [pe-usage.sh](pe-usage.sh) collects the Bytes In and Bytes Out of the last 30 days for all private endpoints in all subscriptions using Azure Monitor Metrics.

The script:

- Finds all Private Endpoints in all subscriptions.
- Queries PEBytesIn and PEBytesOut metrics for the last 30 days.
- Reports Private Endpoints with zero traffic over the period.
- Outputs a CSV `unused-private-endpoints.csv` for further review.

Run it from the repository directory:

```bash
chmod +x pe-usage.sh
./pe-usage.sh
```

Alternatively, run it without changing file permissions:

```bash
bash pe-usage.sh
```

The generated CSV contains these columns:

| Column | Description |
| --- | --- |
| `SubscriptionName` | Subscription display name |
| `SubscriptionId` | Subscription ID |
| `ResourceGroup` | Resource group containing the Private Endpoint |
| `PrivateEndpoint` | Private Endpoint name |
| `Location` | Azure region |
| `TargetServiceType` | Target service type of the Private Endpoint |
| `BytesIn30Days` | Total bytes received by the Private Endpoint in the last 30 days |
| `BytesOut30Days` | Total bytes sent by the Private Endpoint in the last 30 days |

If Azure Monitor does not return a `PEBytesIn` or `PEBytesOut` value, the script records `0` for that Private Endpoint. Existing `unused-private-endpoints.csv` content is replaced each time the script starts.

## Known errors

If you are using an old version of the az cli `resource-graph` extension, you might get errors like this example:

```bash
$ ./pe-usage.sh 
Collecting Private Endpoints from Azure Resource Graph...
ERROR: The command failed with an unexpected error. Here is the traceback:
ERROR: No module named 'pkg_resources'
Traceback (most recent call last):
  File "/usr/lib64/az/lib/python3.12/site-packages/knack/cli.py", line 233, in invoke
    cmd_result = self.invocation.execute(args)
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib64/az/lib/python3.12/site-packages/azure/cli/core/commands/__init__.py", line 567, in execute
    self.commands_loader.load_arguments(command)
  File "/usr/lib64/az/lib/python3.12/site-packages/azure/cli/core/__init__.py", line 657, in load_arguments
    self.command_table[command].load_arguments()  # this loads the arguments via reflection
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib64/az/lib/python3.12/site-packages/azure/cli/core/commands/__init__.py", line 320, in load_arguments
    super().load_arguments()
  File "/usr/lib64/az/lib/python3.12/site-packages/knack/commands.py", line 104, in load_arguments
    cmd_args = self.arguments_loader()
               ^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib64/az/lib/python3.12/site-packages/azure/cli/core/commands/command_operation.py", line 124, in arguments_loader
    op = self.get_op_handler(self.op_path)
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib64/az/lib/python3.12/site-packages/azure/cli/core/commands/command_operation.py", line 59, in get_op_handler
    handler = import_module(mod_to_import)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/importlib/__init__.py", line 90, in import_module
    return _bootstrap._gcd_import(name[level:], package, level)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "<frozen importlib._bootstrap>", line 1387, in _gcd_import
  File "<frozen importlib._bootstrap>", line 1360, in _find_and_load
  File "<frozen importlib._bootstrap>", line 1331, in _find_and_load_unlocked
  File "<frozen importlib._bootstrap>", line 935, in _load_unlocked
  File "<frozen importlib._bootstrap_external>", line 999, in exec_module
  File "<frozen importlib._bootstrap>", line 488, in _call_with_frames_removed
  File "/home/rui/.azure/cliextensions/resource-graph/azext_resourcegraph/custom.py", line 21, in <module>
    from azext_resourcegraph.vendored_sdks.resourcegraph.models import ResultTruncated
  File "/home/rui/.azure/cliextensions/resource-graph/azext_resourcegraph/vendored_sdks/__init__.py", line 6, in <module>
    __import__('pkg_resources').declare_namespace(__name__)
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
ModuleNotFoundError: No module named 'pkg_resources'
To check existing issues, please visit: https://github.com/Azure/azure-cli/issues
```

To solve this issue, you need to update to the last version of the `resource-graph` extension. You can check the current version:

```bash
az extension list --output table
```

And you can update the extension using this command:

```bash
az extension update --name resource-graph
```
