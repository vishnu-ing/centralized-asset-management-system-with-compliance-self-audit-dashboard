#!/bin/bash

# Path to the directory containing playbooks
PLAYBOOK_DIR="/shared/Playbooks"
INVENTORY_DIR="/shared/inventory"
LOCK_FILE="/shared/automation.lock"

# Exit on any error
set -e

# Function to remove the lock file upon exit
cleanup() {
    rm -f "$LOCK_FILE"
}

# Check if the lock file exists
if [ -e "$LOCK_FILE" ]; then
    echo "$(date): Script is already running. Exiting..."
    exit 1
else
    # Create the lock file
    touch "$LOCK_FILE"
    trap cleanup EXIT
fi

echo "$(date): Running Host Discovery..."
ansible-playbook "$PLAYBOOK_DIR/host-discovery"

echo "$(date): Running Nmap Script..."
ansible-playbook "$PLAYBOOK_DIR/nmap-script" -i "$INVENTORY_DIR"

echo "$(date): Gathering Linux System Information..."
ansible-playbook "$PLAYBOOK_DIR/linux-info" -i "$INVENTORY_DIR"

echo "$(date): Gathering Windows System Information..."
ansible-playbook "$PLAYBOOK_DIR/windows-info" -i "$INVENTORY_DIR"

echo "$(date): Checking Linux Compliance..."
ansible-playbook "$PLAYBOOK_DIR/linux-compliance" -i "$INVENTORY_DIR"

echo "$(date): Checking Windows Compliance..."
ansible-playbook "$PLAYBOOK_DIR/windows-compliance" -i "$INVENTORY_DIR"

echo "$(date): Running Lynis Audits..."
ansible-playbook "$PLAYBOOK_DIR/lynis" -i "$INVENTORY_DIR"

echo "$(date): Running Data classification..."
ansible-playbook "$PLAYBOOK_DIR/data-classification" -i "$INVENTORY_DIR"

echo "$(date): Running Software inventory..."
ansible-playbook "$PLAYBOOK_DIR/software-inventory" -i "$INVENTORY_DIR"

echo "$(date): All playbooks executed successfully!"
