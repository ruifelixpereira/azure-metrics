#!/usr/bin/env bash

set -euo pipefail

OUTPUT_FILE="unused-private-endpoints.csv"

echo "SubscriptionId,SubscriptionName,ResourceGroup,PrivateEndpoint,Location,TargetServiceType,BytesIn30Days,BytesOut30Days" > "$OUTPUT_FILE"

START_TIME=$(date -u -d "30 days ago" '+%Y-%m-%dT%H:%M:%SZ')
END_TIME=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

echo "Collecting Private Endpoints from Azure Resource Graph..."

az graph query -q "
resources
| where type =~ 'microsoft.network/privateendpoints'
| extend targetServiceId=tostring(properties.privateLinkServiceConnections[0].properties.privateLinkServiceId)
| extend targetServiceType=tolower(extract('/providers/([^/]+/[^/]+)', 1, targetServiceId))
| join kind=leftouter (
    resourcecontainers
    | where type == 'microsoft.resources/subscriptions'
    | project subscriptionId, subscriptionName=name
) on subscriptionId
| project
    id,
    name,
    resourceGroup,
    location,
    subscriptionId,
    subscriptionName,
    targetServiceType
" -o json |
jq -c '.data[]' |
while read -r pe; do

    PE_ID=$(echo "$pe" | jq -r '.id')
    PE_NAME=$(echo "$pe" | jq -r '.name')
    RG=$(echo "$pe" | jq -r '.resourceGroup')
    LOCATION=$(echo "$pe" | jq -r '.location')
    SUB_ID=$(echo "$pe" | jq -r '.subscriptionId')
    SUB_NAME=$(echo "$pe" | jq -r '.subscriptionName')
    TARGET_SERVICE=$(echo "$pe" | jq -r '.targetServiceType')

    echo "Checking $PE_NAME"

    BYTES_IN=$(
        az monitor metrics list \
            --resource "$PE_ID" \
            --metric PEBytesIn \
            --start-time "$START_TIME" \
            --end-time "$END_TIME" \
            --interval P1D \
            --aggregation Total \
            --query "value[0].timeseries[0].data[].total" \
            -o tsv 2>/dev/null |
        awk '{s+=$1} END {print s+0}'
    )

    BYTES_OUT=$(
        az monitor metrics list \
            --resource "$PE_ID" \
            --metric PEBytesOut \
            --start-time "$START_TIME" \
            --end-time "$END_TIME" \
            --interval P1D \
            --aggregation Total \
            --query "value[0].timeseries[0].data[].total" \
            -o tsv 2>/dev/null |
        awk '{s+=$1} END {print s+0}'
    )

    if [[ "$BYTES_IN" == "0" && "$BYTES_OUT" == "0" ]]; then

        echo "\"$SUB_ID\",\"$SUB_NAME\",\"$RG\",\"$PE_NAME\",\"$LOCATION\",\"$TARGET_SERVICE\",\"$BYTES_IN\",\"$BYTES_OUT\"" \
            >> "$OUTPUT_FILE"

        echo "Candidate cleanup: $PE_NAME"
    fi

done

echo ""
echo "Report generated: $OUTPUT_FILE"
