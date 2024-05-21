#!/bin/bash

# Retrieve list of subnets with names
subnets=$(aws ec2 describe-subnets --query 'Subnets[*].{ID:SubnetId,Name:Tags[?Key==`Name`].Value | [0],CIDR:CidrBlock}' --output json)

# Loop through each subnet
for row in $(echo "${subnets}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }
    
    subnet_id=$(_jq '.ID')
    subnet_name=$(_jq '.Name')
    subnet_cidr=$(_jq '.CIDR')

    # Replace spaces in subnet name with underscores to avoid issues in filenames
    subnet_name_sanitized=$(echo $subnet_name | tr ' ' '_')

    echo "Scanning Subnet: $subnet_name ($subnet_id) with CIDR: $subnet_cidr"

    # Run nmap scan
    nmap -sn $subnet_cidr > "${subnet_name_sanitized}_scan_results.txt"

    echo "Results saved to ${subnet_name_sanitized}_scan_results.txt"
done

echo "All subnets scanned and results saved."