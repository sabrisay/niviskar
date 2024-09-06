#!/bin/bash

# Usage: ./delete_ami_snapshots.sh <path_to_csv_file>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <csv_file>"
    exit 1
fi

CSV_FILE=$1

# Check if the file exists
if [ ! -f "$CSV_FILE" ]; then
    echo "CSV file not found!"
    exit 1
fi

# Loop through each AMI ID in the CSV file (assuming the first row is the AMI ID)
while IFS=, read -r ami_id; do
    echo "Processing AMI ID: $ami_id"

    # Deregister the AMI
    echo "Deregistering AMI: $ami_id"
    aws ec2 deregister-image --image-id "$ami_id"
    
    # Get the associated snapshots from the AMI
    snapshot_ids=$(aws ec2 describe-images --image-ids "$ami_id" \
        --query 'Images[*].BlockDeviceMappings[*].Ebs.SnapshotId' --output text)

    if [ -z "$snapshot_ids" ]; then
        echo "No snapshots found for AMI: $ami_id"
    else
        # Delete the associated snapshots
        for snapshot_id in $snapshot_ids; do
            echo "Deleting snapshot: $snapshot_id"
            aws ec2 delete-snapshot --snapshot-id "$snapshot_id"
        done
    fi

    echo "Finished processing AMI ID: $ami_id"
    echo "--------------------------------"
done < <(tail -n +2 "$CSV_FILE")  # Skip the header row (assuming it's the first row)