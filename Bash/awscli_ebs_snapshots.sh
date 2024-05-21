#!/bin/bash

# Check if region is passed as a parameter
if [ -z "$1" ]; then
  echo "Usage: $0 <region>"
  exit 1
fi

REGION=$1

# Get the account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Define the CSV file name
CSV_FILE="${REGION}_${ACCOUNT_ID}.csv"

# Get snapshots without existing EBS in use
SNAPSHOTS=$(aws ec2 describe-snapshots --region $REGION --query 'Snapshots[?State==`completed`]' --output json)

# Create the CSV file and write the header
echo "SnapshotID,CreationDate,Size(GB),Link" > $CSV_FILE

# Iterate through each snapshot
for snapshot in $(echo "${SNAPSHOTS}" | jq -c '.[]'); do
  SNAPSHOT_ID=$(echo "$snapshot" | jq -r '.SnapshotId')
  CREATION_DATE=$(echo "$snapshot" | jq -r '.StartTime')
  SIZE=$(echo "$snapshot" | jq -r '.VolumeSize')

  # Check if the snapshot is in use
  IN_USE=$(aws ec2 describe-volumes --region $REGION --filters Name=snapshot-id,Values=$SNAPSHOT_ID --query 'Volumes' --output json | jq '. | length')

  if [ "$IN_USE" -eq 0 ]; then
    LINK="https://console.aws.amazon.com/ec2/v2/home?region=$REGION#Snapshots:search=$SNAPSHOT_ID"
    echo "$SNAPSHOT_ID,$CREATION_DATE,$SIZE,$LINK" >> $CSV_FILE
  fi
done

echo "Snapshot details exported to $CSV_FILE"
