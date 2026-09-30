#!/bin/bash

set -uo pipefail

OUTPUT_FILE="storage_inventory.csv"

echo "SubscriptionName,SubscriptionId,ResourceGroup,StorageAccount,Location,SKU,Kind,HnsEnabled,UsedBytes,UsedTB" > "$OUTPUT_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

get_used_capacity() {
    local RESOURCE_ID="$1"
    local SUBSCRIPTION_ID="$2"

    local CAPACITY

    CAPACITY=$(az monitor metrics list \
        --subscription "$SUBSCRIPTION_ID" \
        --resource "$RESOURCE_ID" \
        --metric UsedCapacity \
        --interval PT1H \
        --aggregation Average \
        --query "value[0].timeseries[0].data[-1].average" \
        -o tsv 2>/dev/null)

    if [[ -z "$CAPACITY" || "$CAPACITY" == "null" ]]; then
        echo "0"
    else
        echo "$CAPACITY"
    fi
}

log "Retrieving subscriptions..."

SUBSCRIPTIONS=$(az account list --all -o json 2>/dev/null)

if [[ -z "$SUBSCRIPTIONS" || "$SUBSCRIPTIONS" == "[]" ]]; then
    log "No subscriptions found."
    exit 1
fi

echo "$SUBSCRIPTIONS" | jq -c '.[]' | while read -r SUB
do
    SUB_ID=$(echo "$SUB" | jq -r '.id')
    SUB_NAME=$(echo "$SUB" | jq -r '.name')
    SUB_STATE=$(echo "$SUB" | jq -r '.state')

    if [[ -z "$SUB_ID" ]]; then
        continue
    fi

    if [[ "$SUB_STATE" != "Enabled" ]]; then
        log "Skipping subscription '$SUB_NAME' ($SUB_STATE)"
        continue
    fi

    log "Processing subscription: $SUB_NAME"

    if ! az account show --subscription "$SUB_ID" >/dev/null 2>&1; then
        log "Cannot access subscription $SUB_NAME"
        continue
    fi

    STORAGE_ACCOUNTS=$(az storage account list \
        --subscription "$SUB_ID" \
        -o json 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        log "Failed retrieving storage accounts from $SUB_NAME"
        continue
    fi

    COUNT=$(echo "$STORAGE_ACCOUNTS" | jq 'length')

    log "Found $COUNT storage accounts"

    echo "$STORAGE_ACCOUNTS" | jq -c '.[]' | while read -r SA
    do
        NAME=$(echo "$SA" | jq -r '.name')
        RG=$(echo "$SA" | jq -r '.resourceGroup')
        LOCATION=$(echo "$SA" | jq -r '.location')
        SKU=$(echo "$SA" | jq -r '.sku.name')
        KIND=$(echo "$SA" | jq -r '.kind')
        ID=$(echo "$SA" | jq -r '.id')
        HNS=$(echo "$SA" | jq -r '.isHnsEnabled // false')

        log "Collecting metrics for $NAME"

        USED_BYTES=$(get_used_capacity "$ID" "$SUB_ID")

        USED_TB=$(awk -v b="$USED_BYTES" \
            'BEGIN {printf "%.2f", b/1099511627776}')

        echo "\"$SUB_NAME\",\"$SUB_ID\",\"$RG\",\"$NAME\",\"$LOCATION\",\"$SKU\",\"$KIND\",\"$HNS\",\"$USED_BYTES\",\"$USED_TB\"" \
            >> "$OUTPUT_FILE"

    done
done

log "Completed."
log "CSV generated: $OUTPUT_FILE"