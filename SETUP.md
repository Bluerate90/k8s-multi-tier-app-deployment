# Complete Setup Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Infrastructure Setup](#infrastructure-setup)
3. [NFS Storage Configuration](#nfs-storage-configuration)
4. [Kubernetes Deployment](#kubernetes-deployment)
5. [Dashboard Configuration](#dashboard-configuration)
6. [Verification Steps](#verification-steps)
7. [Post-Deployment Configuration](#post-deployment-configuration)

---

## Prerequisites

### System Requirements
- **Kubernetes Cluster**: v1.20 or higher
- **Nodes**: Minimum 2 worker nodes
- **OS**: Ubuntu 18.04+ or Debian 10+
- **RAM**: 4GB minimum per node
- **CPU**: 2 cores minimum per node
- **Storage**: 20GB available

### Required Tools
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client
```

### Network Requirements
- NodePort range: 30000-32767 available
- Port 30080 accessible for WordPress
- NFS ports open between nodes (TCP/UDP 2049, 111)

---

## Infrastructure Setup

### 1. Prepare the Kubernetes Cluster

Ensure your cluster is running:
```bash
kubectl cluster-info
kubectl get nodes
```

Expected output:
```
NAME            STATUS   ROLES           AGE   VERSION
master-node     Ready    control-plane   10d   v1.26.0
worker-node-1   Ready    <none>          10d   v1.26.0
worker-node-2   Ready    <none>          10d   v1.26.0
```

### 2. Label Worker Nodes (Optional)

Label nodes for better organization:
```bash
kubectl label nodes worker-node-1 role=nfs-server
kubectl label nodes worker-node-2 role=worker
```

---

## NFS Storage Configuration

### Step 1: Setup NFS Server (worker-node-1)

SSH into worker-node-1:
```bash
ssh user@worker-node-1
```

Run the NFS server setup script:
```bash
cd nfs-setup
chmod +x nfs-server-setup.sh
sudo ./nfs-server-setup.sh
```

**Manual Setup (Alternative):**
```bash
# Create directory
sudo mkdir -p /mydbdata

# Install NFS server
sudo apt update
sudo apt install -y nfs-kernel-server

# Configure exports
echo "/mydbdata  *(rw,sync,no_root_squash)" | sudo tee -a /etc/exports

# Apply exports
sudo exportfs -rv

# Set permissions
sudo chown nobody:nogroup /mydbdata/
sudo chmod 777 /mydbdata/

# Start and enable service
sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server

# Get server IP
ip a | grep "inet " | grep -v "127.0.0.1"
```

**Important**: Note the IP address - you'll need it for the PersistentVolume configuration.

### Step 2: Setup NFS Client (worker-node-2)

SSH into worker-node-2:
```bash
ssh user@worker-node-2
```

Run the NFS client setup script:
```bash
cd nfs-setup
chmod +x nfs-client-setup.sh
sudo ./nfs-client-setup.sh
```

**Manual Setup (Alternative):**
```bash
# Install NFS common
sudo apt update
sudo apt install -y nfs-common

# Refresh service
sudo rm -f /lib/systemd/system/nfs-common.service
sudo systemctl daemon-reload
```

### Step 3: Verify NFS Setup

From any node with NFS client installed:
```bash
# Test NFS mount
showmount -e <NFS-SERVER-IP>

# Should show:
# Export list for <NFS-SERVER-IP>:
# /mydbdata *
```

---

## Kubernetes Deployment

### Step 1: Clone Repository

```bash
git clone https://github.com/yourusername/kubernetes-mysql-wordpress-deployment.git
cd kubernetes-mysql-wordpress-deployment
```

### Step 2: Update Configuration

Edit `manifests/storage/pv.yaml` and replace `<NFS-SERVER-IP>` with your actual NFS server IP:
```bash
# Get NFS server IP first
NFS_IP=$(kubectl get nodes worker-node-1 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
echo "NFS Server IP: $NFS_IP"

# Update the PV manifest
sed -i "s/<NFS-SERVER-IP>/$NFS_IP/g" manifests/storage/pv.yaml
```

### Step 3: Deploy Using Automated Script

```bash
cd scripts
chmod +x deploy-all.sh
./deploy-all.sh
```

The script will prompt you for:
1. NFS Server IP address
2. MySQL root password (keep this secure!)

### Step 4: Manual Deployment (Alternative)

If you prefer manual deployment:

**Create Namespace:**
```bash
kubectl apply -f manifests/namespace.yaml
```

**Create ConfigMap:**
```bash
kubectl apply -f manifests/configmap/wordpress-config.yaml
```

**Create Secret:**
```bash
kubectl create secret generic mysql-pass \
  --from-literal=password='YourSecurePassword123!' \
  -n wordpress-mysql-app
```

**Create Storage:**
```bash
kubectl apply -f manifests/storage/pv.yaml
kubectl apply -f manifests/storage/pvc.yaml
```

**Deploy MySQL:**
```bash
kubectl apply -f manifests/deployments/mysql-deployment.yaml
kubectl apply -f manifests/services/mysql-service.yaml
```

**Deploy WordPress:**
```bash
kubectl apply -f manifests/deployments/wordpress-deployment.yaml
kubectl apply -f manifests/services/wordpress-service.yaml
```

**Apply Resource Limits (Optional):**
```bash
kubectl apply -f manifests/resourcequota.yaml
kubectl apply -f manifests/limitrange.yaml
```

---

## Dashboard Configuration

### Step 1: Install Kubernetes Dashboard

```bash
cd dashboard
chmod +x dashboard-setup.sh
./dashboard-setup.sh
```

**Manual Installation (Alternative):**
```bash
# Deploy dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create admin user
kubectl apply -f dashboard/create-admin-user.yaml

# Wait for dashboard to be ready
kubectl wait --for=condition=ready pod \
  -l k8s-app=kubernetes-dashboard \
  -n kubernetes-dashboard --timeout=120s
```

### Step 2: Access Dashboard

**Start kubectl proxy:**
```bash
kubectl proxy
```

**Get access token:**
```bash
kubectl -n kubernetes-dashboard create token admin-user
```

**Access URL:**
```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

**Login:**
- Select "Token" authentication
- Paste the token from the previous command
- Click "Sign In"

---

## Verification Steps

### Step 1: Check Deployment Status

Run the verification script:
```bash
cd scripts
chmod +x verify-deployment.sh
./verify-deployment.sh
```

### Step 2: Manual Verification

**Check all resources:**
```bash
kubectl get all -n wordpress-mysql-app
```

**Check pods are running:**
```bash
kubectl get pods -n wordpress-mysql-app

# Expected output:
# NAME                         READY   STATUS    RESTARTS   AGE
# mysql-xxxxxxxxxx-xxxxx       1/1     Running   0          5m
# wordpress-xxxxxxxxxx-xxxxx   1/1     Running   0          4m
```

**Check services:**
```bash
kubectl get svc -n wordpress-mysql-app

# Expected output:
# NAME        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# mysql       ClusterIP   10.96.xxx.xxx   <none>        3306/TCP       5m
# wordpress   NodePort    10.96.xxx.xxx   <none>        80:30080/TCP   4m
```

**Check PV and PVC:**
```bash
kubectl get pv,pvc -n wordpress-mysql-app

# PVC should show STATUS: Bound
```

**Check pod logs:**
```bash
# MySQL logs
kubectl logs -l app=mysql -n wordpress-mysql-app

# WordPress logs
kubectl logs -l app=wordpress -n wordpress-mysql-app
```

### Step 3: Test Connectivity

**Test MySQL pod:**
```bash
MYSQL_POD=$(kubectl get pod -n wordpress-mysql-app -l app=mysql -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n wordpress-mysql-app $MYSQL_POD -- mysql --version
```

**Test WordPress pod:**
```bash
WP_POD=$(kubectl get pod -n wordpress-mysql-app -l app=wordpress -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n wordpress-mysql-app $WP_POD -- curl -s http://localhost | head -n 5
```

---

## Post-Deployment Configuration

### Step 1: Access WordPress

Get your node IP:
```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Access WordPress at: http://$NODE_IP:30080"
```

Open your browser and navigate to: `http://<NODE-IP>:30080`

### Step 2: Complete WordPress Setup

1. **Select Language**: Choose your preferred language
2. **Site Information**:
   - Site Title: (Already set from ConfigMap)
   - Username: Choose admin username
   - Password: Create a strong password
   - Email: (Already set from ConfigMap)
3. **Install WordPress**: Click the install button
4. **Login**: Use your credentials to access the WordPress admin panel

### Step 3: Configure WordPress Database

The database connection is already configured via environment variables:
- Database Host: `mysql:3306`
- Database Name: `database1`
- Database User: `root`
- Database Password: (from Secret)

### Step 4: Verify Data Persistence

**Create a test post in WordPress**, then:

```bash
# Delete the WordPress pod
kubectl delete pod -l app=wordpress -n wordpress-mysql-app

# Wait for new pod to start
kubectl wait --for=condition=ready pod -l app=wordpress -n wordpress-mysql-app --timeout=120s

# Access WordPress again - your post should still be there
```

### Step 5: Monitor Resources

**Check resource usage:**
```bash
kubectl top nodes
kubectl top pods -n wordpress-mysql-app
```

**View resource quotas:**
```bash
kubectl describe resourcequota wordpress-mysql-quota -n wordpress-mysql-app
```

---

## Common Issues and Solutions

### Issue 1: PVC Stuck in Pending

**Symptom:**
```bash
kubectl get pvc -n wordpress-mysql-app
# STATUS: Pending
```

**Solution:**
```bash
# Check PV status
kubectl get pv

# Describe PVC for details
kubectl describe pvc mysql-pvc -n wordpress-mysql-app

# Common fixes:
# 1. Verify NFS server is running
sudo systemctl status nfs-kernel-server

# 2. Verify exports
showmount -e <NFS-SERVER-IP>

# 3. Check PV selector labels match
kubectl get pv mysql-pv -o yaml | grep -A 5 labels
```

### Issue 2: MySQL Pod Not Starting

**Symptom:**
```bash
kubectl get pods -n wordpress-mysql-app
# mysql pod: CrashLoopBackOff or Error
```

**Solution:**
```bash
# Check pod logs
kubectl logs -l app=mysql -n wordpress-mysql-app

# Check pod events
kubectl describe pod -l app=mysql -n wordpress-mysql-app

# Common fixes:
# 1. Verify secret exists
kubectl get secret mysql-pass -n wordpress-mysql-app

# 2. Check volume mounts
kubectl describe pod -l app=mysql -n wordpress-mysql-app | grep -A 10 "Mounts:"

# 3. Verify NFS mount works manually
sudo mount -t nfs <NFS-SERVER-IP>:/mydbdata /mnt
ls -la /mnt
sudo umount /mnt
```

### Issue 3: Cannot Access WordPress

**Symptom:** Browser cannot connect to `http://<NODE-IP>:30080`

**Solution:**
```bash
# 1. Verify service
kubectl get svc wordpress -n wordpress-mysql-app

# 2. Check if NodePort is accessible
curl http://localhost:30080

# 3. Check firewall rules
sudo ufw status
sudo ufw allow 30080/tcp

# 4. Verify pod is running
kubectl get pods -l app=wordpress -n wordpress-mysql-app

# 5. Check pod logs
kubectl logs -l app=wordpress -n wordpress-mysql-app
```

### Issue 4: WordPress Cannot Connect to MySQL

**Symptom:** WordPress shows database connection error

**Solution:**
```bash
# 1. Verify MySQL service
kubectl get svc mysql -n wordpress-mysql-app

# 2. Test connectivity from WordPress pod
WP_POD=$(kubectl get pod -n wordpress-mysql-app -l app=wordpress -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n wordpress-mysql-app $WP_POD -- nc -zv mysql 3306

# 3. Verify secret
kubectl get secret mysql-pass -n wordpress-mysql-app -o jsonpath='{.data.password}' | base64 -d

# 4. Check MySQL logs
kubectl logs -l app=mysql -n wordpress-mysql-app
```

---

## Security Best Practices

### 1. Secure MySQL Password

```bash
# Use a strong password
openssl rand -base64 32

# Create secret from file
echo -n "your-strong-password" > password.txt
kubectl create secret generic mysql-pass \
  --from-file=password=password.txt \
  -n wordpress-mysql-app
rm password.txt
```

### 2. Network Policies (Optional)

Create network policies to restrict traffic:
```yaml
# manifests/network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mysql-network-policy
  namespace: wordpress-mysql-app
spec:
  podSelector:
    matchLabels:
      app: mysql
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: wordpress
    ports:
    - protocol: TCP
      port: 3306
```

### 3. Update Images

Regularly update to patched versions:
```bash
# Update MySQL
kubectl set image deployment/mysql mysql=mysql:5.6.51 -n wordpress-mysql-app

# Update WordPress
kubectl set image deployment/wordpress wordpress=wordpress:latest -n wordpress-mysql-app
```

---

## Backup and Recovery

### Backup MySQL Data

```bash
# Export database
MYSQL_POD=$(kubectl get pod -n wordpress-mysql-app -l app=mysql -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n wordpress-mysql-app $MYSQL_POD -- mysqldump -uroot -p$MYSQL_PASSWORD database1 > backup.sql

# Or backup NFS data directly
sudo tar -czf mydbdata-backup-$(date +%Y%m%d).tar.gz /mydbdata/
```

### Restore MySQL Data

```bash
# Import database
cat backup.sql | kubectl exec -i -n wordpress-mysql-app $MYSQL_POD -- mysql -uroot -p$MYSQL_PASSWORD database1
```

---

## Scaling Considerations

### Scale WordPress

```bash
# Scale WordPress replicas
kubectl scale deployment wordpress --replicas=3 -n wordpress-mysql-app

# Verify scaling
kubectl get pods -l app=wordpress -n wordpress-mysql-app
```

**Note:** MySQL is configured with `strategy: Recreate` for single-instance deployment. For production, consider MySQL replication or managed database services.

---

## Next Steps

1. **Setup Ingress Controller** for production-grade routing
2. **Implement TLS/SSL** for secure connections
3. **Configure Horizontal Pod Autoscaling** for WordPress
4. **Setup Monitoring** with Prometheus and Grafana
5. **Implement CI/CD Pipeline** for automated deployments
6. **Configure Backup Strategy** for disaster recovery

---

## Support and Documentation

- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **WordPress Documentation**: https://wordpress.org/support/
- **MySQL Documentation**: https://dev.mysql.com/doc/
- **NFS Documentation**: https://linux.die.net/man/5/exports

---

**Last Updated:** October 2025  
**Version:** 1.0.0
