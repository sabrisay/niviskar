#!/bin/bash

# Check if CSV file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <ip_list.csv>"
    echo "CSV file should contain IP addresses, one per line"
    exit 1
fi

# Configuration
NEW_USER="vuln_scanner"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
TARGET_USER="ec2-user"  # User on target instances

# Check if SSH key exists
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "SSH key not found at $SSH_KEY_PATH"
    echo "Please generate an SSH key pair first using: ssh-keygen -t rsa"
    exit 1
fi

# Read IPs from CSV file
while IFS=, read -r ip; do
    # Remove any whitespace from IP
    ip=$(echo "$ip" | tr -d '[:space:]')
    
    echo "Processing IP: $ip"
    
    # Create user and add to sudoers on target instance
    ssh $TARGET_USER@$ip "
        # Create user if doesn't exist
        if ! id '$NEW_USER' &>/dev/null; then
            sudo useradd -m -s /bin/bash '$NEW_USER'
            echo '$NEW_USER ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/$NEW_USER
            sudo chmod 440 /etc/sudoers.d/$NEW_USER
        fi
        
        # Create .ssh directory and set permissions
        sudo mkdir -p /home/$NEW_USER/.ssh
        sudo chown $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
        sudo chmod 700 /home/$NEW_USER/.ssh
    "
    
    # Copy SSH key to target instance
    cat "$SSH_KEY_PATH" | ssh $TARGET_USER@$ip "
        sudo tee -a /home/$NEW_USER/.ssh/authorized_keys
        sudo chown $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh/authorized_keys
        sudo chmod 600 /home/$NEW_USER/.ssh/authorized_keys
    "
    
    echo "Completed setup for IP: $ip"
    echo "----------------------------------------"
done < "$1"

echo "Setup completed for all IPs"
