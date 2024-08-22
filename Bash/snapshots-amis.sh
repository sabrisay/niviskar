#!/bin/bash

# Set the AMI ID
AMI_ID="ami-xxxxxxxxxxxxxxxxx"

# Deregister the AMI
aws ec2 deregister-image --image-id $AMI_ID
echo "Deregistered AMI: $AMI_ID"

# Get the list of snapshots associated with the AMI
SNAPSHOT_IDS=$(aws ec2 describe-snapshots --filters "Name=description,Values=*$AMI_ID*" --query "Snapshots[*].SnapshotId" --output text)

# Delete each snapshot
for SNAPSHOT_ID in $SNAPSHOT_IDS; do
    aws ec2 delete-snapshot --snapshot-id $SNAPSHOT_ID
    echo "Deleted snapshot: $SNAPSHOT_ID"
done

echo "Cleanup complete."