# ============================================
# File: dashboard/dashboard-setup.sh
# Description: Setup Kubernetes Dashboard
# ============================================

#!/bin/bash
set -e

echo "=========================================="
echo "  Kubernetes Dashboard Setup             "
echo "=========================================="

# Install Dashboard
echo "1. Installing Kubernetes Dashboard..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create admin user
echo "2. Creating admin user..."
kubectl apply -f create-admin-user.yaml

# Wait for dashboard to be ready
echo "3. Waiting for dashboard to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=120s

# Get token
echo ""
echo "=========================================="
echo "         Dashboard Setup Complete         "
echo "=========================================="
echo ""
echo "To access the dashboard:"
echo "1. Run: kubectl proxy"
echo "2. Visit: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo ""
echo "3. Get your token with:"
echo "   kubectl -n kubernetes-dashboard create token admin-user"
echo ""
echo "Token (valid for 1 hour):"
kubectl -n kubernetes-dashboard create token admin-user
echo ""
