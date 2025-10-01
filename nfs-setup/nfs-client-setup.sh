# ============================================
# File: nfs-setup/nfs-client-setup.sh
# Description: Setup NFS client on worker-node-2
# ============================================

#!/bin/bash
set -e

echo "=== NFS Client Setup Script ==="

# Install NFS common
echo "[1/3] Installing NFS common package..."
sudo apt update
sudo apt install -y nfs-common

# Remove and reload service
echo "[2/3] Refreshing NFS common service..."
if [ -f /lib/systemd/system/nfs-common.service ]; then
    sudo rm /lib/systemd/system/nfs-common.service
fi
sudo systemctl daemon-reload

# Verify installation
echo "[3/3] Verifying NFS client setup..."
dpkg -l | grep nfs-common

echo ""
echo "=== NFS Client Setup Complete! ==="
echo "The node is ready to mount NFS volumes"
