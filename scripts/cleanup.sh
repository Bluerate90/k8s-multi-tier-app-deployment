# ============================================
# File: scripts/cleanup.sh
# Description: Clean up all resources
# ============================================

#!/bin/bash

echo "=========================================="
echo "    Cleanup Script - CAUTION!            "
echo "=========================================="
echo ""
echo "This will delete all WordPress and MySQL resources."
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

NAMESPACE="wordpress-mysql-app"

echo ""
echo "Deleting deployments..."
kubectl delete deployment mysql wordpress -n $NAMESPACE --ignore-not-found=true

echo "Deleting services..."
kubectl delete service mysql wordpress -n $NAMESPACE --ignore-not-found=true

echo "Deleting PVCs..."
kubectl delete pvc mysql-pvc -n $NAMESPACE --ignore-not-found=true

echo "Deleting PVs..."
kubectl delete pv mysql-pv --ignore-not-found=true

echo "Deleting ConfigMaps..."
kubectl delete configmap wordpress-config -n $NAMESPACE --ignore-not-found=true

echo "Deleting Secrets..."
kubectl delete secret mysql-pass -n $NAMESPACE --ignore-not-found=true

echo "Deleting namespace..."
kubectl delete namespace $NAMESPACE --ignore-not-found=true

echo ""
echo "Cleanup complete!"
echo ""
echo "Note: NFS data at /mydbdata on the server was NOT deleted."
echo "To remove NFS data, run: sudo rm -rf /mydbdata"

