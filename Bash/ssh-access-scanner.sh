#!/bin/bash

# CONFIGURATION
NEW_USER="newuser"  # change as needed
PUB_KEY_PATH="$HOME/.ssh/id_rsa.pub"
SERVERS_FILE="./servers.txt"
EXISTING_REMOTE_USER="existing_user"
SSH_OPTIONS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

# Log files
SUCCESS_LOG="success_ips.txt"
FAIL_LOG="failed_ips.txt"

# Clear previous logs
> "$SUCCESS_LOG"
> "$FAIL_LOG"

# Ensure your public key exists
if [ ! -f "$PUB_KEY_PATH" ]; then
    echo "Public key $PUB_KEY_PATH not found!"
    exit 1
fi

PUB_KEY_CONTENT=$(cat "$PUB_KEY_PATH")

while read -r SERVER; do
    echo "Configuring $SERVER..."

    ssh $SSH_OPTIONS "$EXISTING_REMOTE_USER@$SERVER" bash -s << EOF
        set -e
        # Create user if it doesn't exist
        if ! id "$NEW_USER" &>/dev/null; then
            sudo useradd -m -s /bin/bash "$NEW_USER"
        fi

        # Optional: Add user to sudoers
        sudo usermod -aG sudo "$NEW_USER"

        # Setup .ssh directory
        sudo mkdir -p /home/$NEW_USER/.ssh
        sudo chmod 700 /home/$NEW_USER/.ssh

        # Add the public key if not already added
        if ! grep -qxF "$PUB_KEY_CONTENT" /home/$NEW_USER/.ssh/authorized_keys 2>/dev/null; then
            echo "$PUB_KEY_CONTENT" | sudo tee -a /home/$NEW_USER/.ssh/authorized_keys >/dev/null
        fi

        sudo chmod 600 /home/$NEW_USER/.ssh/authorized_keys
        sudo chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
EOF

    # Check if SSH command succeeded or failed
    if [ $? -eq 0 ]; then
        echo "$SERVER" >> "$SUCCESS_LOG"
        echo "✅ Successfully configured $SERVER"
    else
        echo "$SERVER" >> "$FAIL_LOG"
        echo "❌ Failed configuring $SERVER"
    fi

    echo "------------------------------------"
done < "$SERVERS_FILE"

# Summary output
echo -e "\n===== Summary ====="
echo "✅ Successful IPs logged in: $SUCCESS_LOG"
echo "❌ Failed IPs logged in: $FAIL_LOG"