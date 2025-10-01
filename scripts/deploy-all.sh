# ============================================
# File: scripts/deploy-all.sh
# Description: Complete deployment script
# ============================================

#!/bin/bash
set -e

echo "=========================================="
echo "  Kubernetes WordPress+MySQL Deployment  "
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Get NFS server IP
echo "Please enter the NFS Server IP address (worker-node-1):"
read -r NFS_SERVER_IP

if [ -z "$NFS_SERVER_IP" ]; then
    print_error "NFS Server IP cannot be empty"
    exit 1
fi

print_status "Using NFS Server IP: $NFS_SERVER_IP"

# Update PV manifest with NFS server IP
print_status "Updating PersistentVolume manifest..."
sed -i "s/<NFS-SERVER-IP>/$NFS_SERVER_IP/g" ../manifests/storage/pv.yaml

# Step 1: Create namespace
print_status "Creating namespace..."
kubectl apply -f ../manifests/namespace.yaml

# Step 2: Create ConfigMap
print_status "Creating ConfigMap..."
kubectl apply -f ../manifests/configmap/wordpress-config.yaml

# Step 3: Create Secret
print_status "Creating MySQL Secret..."
read -sp "Enter MySQL root password: " MYSQL_PASSWORD
echo ""
kubectl create secret generic mysql-pass \
    --from-literal=password="$MYSQL_PASSWORD" \
    -n wordpress-mysql-app \
    --dry-run=client -o yaml | kubectl apply -f -

# Step 4: Create Storage
print_status "Creating PersistentVolume and PersistentVolumeClaim..."
kubectl apply -f ../manifests/storage/pv.yaml
kubectl apply -f ../manifests/storage/pvc.yaml

# Wait for PVC to be bound
print_status "Waiting for PVC to be bound..."
kubectl wait --for=condition=bound pvc/mysql-pvc -n wordpress-mysql-app --timeout=60s || true

# Step 5: Deploy MySQL
print_status "Deploying MySQL..."
kubectl apply -f ../manifests/deployments/mysql-deployment.yaml
kubectl apply -f ../manifests/services/mysql-service.yaml

# Wait for MySQL to be ready
print_status "Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n wordpress-mysql-app --timeout=120s

# Step 6: Deploy WordPress
print_status "Deploying WordPress..."
kubectl apply -f ../manifests/deployments/wordpress-deployment.yaml
kubectl apply -f ../manifests/services/wordpress-service.yaml

# Wait for WordPress to be ready
print_status "Waiting for WordPress to be ready..."
kubectl wait --for=condition=ready pod -l app=wordpress -n wordpress-mysql-app --timeout=120s

# Optional: Apply resource quotas
if [ -f ../manifests/resourcequota.yaml ]; then
    print_status "Applying resource quotas..."
    kubectl apply -f ../manifests/resourcequota.yaml
fi

if [ -f ../manifests/limitrange.yaml ]; then
    print_status "Applying limit ranges..."
    kubectl apply -f ../manifests/limitrange.yaml
fi

# Get deployment status
echo ""
echo "=========================================="
echo "         Deployment Summary               "
echo "=========================================="
echo ""

kubectl get all -n wordpress-mysql-app

echo ""
print_status "Deployment completed successfully!"
echo ""

# Get node IP for access
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Access WordPress at: http://$NODE_IP:30080"
echo ""

print_warning "Next steps:"
echo "1. Access WordPress at the URL above"
echo "2. Complete the WordPress setup wizard"
echo "3. Setup Kubernetes Dashboard (see dashboard/dashboard-setup.sh)"
