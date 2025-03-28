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
NO_ACCESS_FILE="no_access.csv"

# Clear or create no_access.csv file
> "$NO_ACCESS_FILE"

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
    
    # Test SSH connection first
    if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no $TARGET_USER@$ip "echo 'Connection test successful'" &>/dev/null; then
        echo "Failed to connect to $ip - Adding to no_access.csv"
        echo "$ip" >> "$NO_ACCESS_FILE"
        continue
    fi
    
    # Create user and add to sudoers on target instance
    if ! ssh $TARGET_USER@$ip "
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
    "; then
        echo "Failed to create user on $ip - Adding to no_access.csv"
        echo "$ip" >> "$NO_ACCESS_FILE"
        continue
    fi
    
    # Copy SSH key to target instance
    if ! cat "$SSH_KEY_PATH" | ssh $TARGET_USER@$ip "
        sudo tee -a /home/$NEW_USER/.ssh/authorized_keys
        sudo chown $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh/authorized_keys
        sudo chmod 600 /home/$NEW_USER/.ssh/authorized_keys
    "; then
        echo "Failed to copy SSH key to $ip - Adding to no_access.csv"
        echo "$ip" >> "$NO_ACCESS_FILE"
        continue
    fi
    
    echo "Completed setup for IP: $ip"
    echo "----------------------------------------"
done < "$1"

# Print summary
echo "Setup completed"
echo "----------------------------------------"
echo "Inaccessible IPs have been saved to $NO_ACCESS_FILE"
if [ -s "$NO_ACCESS_FILE" ]; then
    echo "Number of inaccessible IPs: $(wc -l < "$NO_ACCESS_FILE")"
    echo "Inaccessible IPs:"
    cat "$NO_ACCESS_FILE"
else
    echo "All IPs were successfully processed"
fi
