#!/bin/bash

# Check if CSV file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <csv-file>"
    exit 1
fi

CSV_FILE=$1

# Path to your public SSH key
PUBLIC_KEY="~/.ssh/id_rsa.pub"

# New username to create
NEW_USER="jumpuser"

# Loop through IP addresses from the CSV file
while IFS=, read -r ip
do
    echo "Connecting to $ip to create user and copy SSH key"

    # Create new user and add to sudo group
    ssh ubuntu@"$ip" "sudo useradd -m -s /bin/bash -G sudo $NEW_USER && sudo mkdir -p /home/$NEW_USER/.ssh && sudo chown $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh && sudo chmod 700 /home/$NEW_USER/.ssh"

    # Copy public SSH key
    ssh-copy-id -i "$PUBLIC_KEY" "$NEW_USER@$ip"

    if [ $? -eq 0 ]; then
        echo "Successfully created user $NEW_USER and copied SSH key to $ip"
    else
        echo "Failed to set up user $NEW_USER or copy SSH key to $ip"
    fi

done < "$CSV_FILE"
