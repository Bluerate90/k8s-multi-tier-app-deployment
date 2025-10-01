#!/bin/bash
# ============================================
# File: nfs-setup/nfs-server-setup.sh
# Description: Setup NFS server on worker-node-1
# ============================================

set -e

echo "=== NFS Server Setup Script ==="
echo "This script will configure NFS server for Kubernetes persistent storage"

# Create directory
echo "[1/8] Creating NFS directory..."
sudo mkdir -p /mydbdata

# Install NFS kernel server
echo "[2/8] Installing NFS kernel server..."
sudo apt update
sudo apt install -y nfs-kernel-server

# Configure exports
echo "[3/8] Configuring NFS exports..."
if ! grep -q "/mydbdata" /etc/exports; then
    echo "/mydbdata  *(rw,sync,no_root_squash)" | sudo tee -a /etc/exports
    echo "Export configuration added"
else
    echo "Export configuration already exists"
fi

# Export all shared directories
echo "[4/8] Exporting shared directories..."
sudo exportfs -rv

# Set permissions
echo "[5/8] Setting directory permissions..."
sudo chown nobody:nogroup /mydbdata/
sudo chmod 777 /mydbdata/

# Restart NFS server
echo "[6/8] Restarting NFS kernel server..."
sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server

# Get server IP
echo "[7/8] Retrieving server IP address..."
SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
echo "NFS Server IP: $SERVER_IP"

# Verify setup
echo "[8/8] Verifying NFS server status..."
sudo systemctl status nfs-kernel-server --no-pager
showmount -e localhost

echo ""
echo "=== NFS Server Setup Complete! ==="
echo "Server IP: $SERVER_IP"
echo "Exported Path: /mydbdata"
echo ""
echo "Next steps:"
echo "1. Update manifests/storage/pv.yaml with this IP address"
echo "2. Run nfs-client-setup.sh on worker-node-2"
