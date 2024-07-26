#!/bin/bash

# Retrieve the list of EBS snapshot IDs from your AMIs and save to a file
aws ec2 describe-images --owners self --query 'Images[*].BlockDeviceMappings[*].Ebs.SnapshotId' --output json > snapshots.json

# Define the snapshot ID to check
snapshot_id_to_check="snap-1234567890abcdef0"

# Use jq to check if the snapshot ID exists in the JSON file
if jq -e --arg snap_id "$snapshot_id_to_check" 'any(.[][]; . == $snap_id)' snapshots.json > /dev/null; then
    echo "Snapshot ID $snapshot_id_to_check exists."
else
    echo "Snapshot ID $snapshot_id_to_check does not exist."
fi