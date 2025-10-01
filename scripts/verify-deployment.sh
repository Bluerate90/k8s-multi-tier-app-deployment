# ============================================
# File: scripts/verify-deployment.sh
# Description: Verify all components are working
# ============================================

#!/bin/bash

echo "=========================================="
echo "    Deployment Verification Script       "
echo "=========================================="
echo ""

NAMESPACE="wordpress-mysql-app"

# Check namespace
echo "1. Checking namespace..."
kubectl get namespace $NAMESPACE

echo ""
echo "2. Checking ConfigMaps..."
kubectl get configmap -n $NAMESPACE

echo ""
echo "3. Checking Secrets..."
kubectl get secrets -n $NAMESPACE

echo ""
echo "4. Checking PersistentVolumes..."
kubectl get pv

echo ""
echo "5. Checking PersistentVolumeClaims..."
kubectl get pvc -n $NAMESPACE

echo ""
echo "6. Checking Deployments..."
kubectl get deployments -n $NAMESPACE

echo ""
echo "7. Checking Pods..."
kubectl get pods -n $NAMESPACE -o wide

echo ""
echo "8. Checking Services..."
kubectl get svc -n $NAMESPACE

echo ""
echo "9. Checking Pod Events..."
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'

echo ""
echo "10. Testing MySQL Connection..."
MYSQL_POD=$(kubectl get pod -n $NAMESPACE -l app=mysql -o jsonpath='{.items[0].metadata.name}')
if [ -n "$MYSQL_POD" ]; then
    echo "MySQL Pod: $MYSQL_POD"
    kubectl exec -n $NAMESPACE $MYSQL_POD -- mysql --version
else
    echo "MySQL pod not found"
fi

echo ""
echo "11. Testing WordPress Connection..."
WORDPRESS_POD=$(kubectl get pod -n $NAMESPACE -l app=wordpress -o jsonpath='{.items[0].metadata.name}')
if [ -n "$WORDPRESS_POD" ]; then
    echo "WordPress Pod: $WORDPRESS_POD"
    kubectl exec -n $NAMESPACE $WORDPRESS_POD -- php --version
else
    echo "WordPress pod not found"
fi

echo ""
echo "=========================================="
echo "         Verification Complete            "
echo "=========================================="
