#!/bin/bash

# Ensure you have jq installed for JSON processing
if ! command -v jq &> /dev/null
then
    echo "jq could not be found, please install it before running this script."
    exit
fi

# Define the output CSV file
output_file="unused_amis.csv"

# Write the header to the CSV file
echo "AMI ID,Name,Creation Date" > $output_file

# Get all AMIs owned by the account
aws ec2 describe-images --owners self --query 'Images[*].[ImageId,Name,CreationDate]' --output json | jq -c '.[]' | while read -r ami; do
    ami_id=$(echo $ami | jq -r '.[0]')
    ami_name=$(echo $ami | jq -r '.[1]')
    ami_creation_date=$(echo $ami | jq -r '.[2]')
    
    # Check if the AMI is used by any instance
    used=$(aws ec2 describe-instances --filters "Name=image-id,Values=$ami_id" --query "Reservations[*].Instances[*].InstanceId" --output text)
    
    # If no instances are using this AMI, add it to the CSV file
    if [ -z "$used" ]; then
        echo "$ami_id,$ami_name,$ami_creation_date" >> $output_file
    fi
done

echo "Unused AMIs have been listed in $output_file"