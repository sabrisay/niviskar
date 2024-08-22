#!/bin/bash

# Set the AMI ID
AMI_ID="ami-xxxxxxxxxxxxxxxxx"

# Deregister the AMI
aws ec2 deregister-image --image-id $AMI_ID
echo "Deregistered AMI: $AMI_ID"

# Get the Block Device Mappings for the AMI to identify snapshots
SNAPSHOT_IDS=$(aws ec2 describe-images --image-ids $AMI_ID --query "Images[*].BlockDeviceMappings[*].Ebs.SnapshotId" --output text)

# Check if any snapshots were found
if [ -z "$SNAPSHOT_IDS" ]; then
    echo "No snapshots found for AMI: $AMI_ID"
    exit 0
fi

# Delete each snapshot
for SNAPSHOT_ID in $SNAPSHOT_IDS; do
    aws ec2 delete-snapshot --snapshot-id $SNAPSHOT_ID
    echo "Deleted snapshot: $SNAPSHOT_ID"
done

echo "Cleanup complete."