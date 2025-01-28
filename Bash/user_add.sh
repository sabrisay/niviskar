#!/bin/bash
# Update the system
yum update -y

# Define the username
USERNAME="newuser"

# Add the user
useradd -m -s /bin/bash $USERNAME

# Set a password for the user (optional, for SSH key-based access this can be skipped)
echo "$USERNAME:password123" | chpasswd

# Add the user to the sudo group
usermod -aG wheel $USERNAME

# Create the .ssh directory for the user
mkdir -p /home/$USERNAME/.ssh
chmod 700 /home/$USERNAME/.ssh

# Add your public SSH key for the user
echo "ssh-rsa AAAAB3Nza...your-public-key" > /home/$USERNAME/.ssh/authorized_keys
chmod 600 /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh

# Ensure SELinux contexts are correct (if using SELinux)
restorecon -Rv /home/$USERNAME/.ssh

# Print success message
echo "User $USERNAME added successfully and SSH key configured."