# Troubleshooting Guide

## Quick Diagnosis

### Check Overall Status
```bash
# All resources in namespace
kubectl get all -n wordpress-mysql-app

# Check pod status
kubectl get pods -n wordpress-mysql-app -o wide

# Check events
kubectl get events -n wordpress-mysql-app --sort-by='.lastTimestamp'
```

## Pod Issues

### Problem: Pod Stuck in Pending

**Symptoms:**
```bash
NAME                         READY   STATUS    RESTARTS   AGE
mysql-xxxxx-xxxxx            0/1     Pending   0          5m
```

**Diagnosis:**
```bash
# Describe the pod
kubectl describe pod mysql-xxxxx-xxxxx -n wordpress-mysql-app

# Common causes in output:
# - "Insufficient cpu" or "Insufficient memory"
# - "no persistent volumes available"
# - "node(s) had taints that the pod didn't tolerate"
```

**Solutions:**

1. **Insufficient Resources:**
```bash
# Check node resources
kubectl top nodes

# Check resource quotas
kubectl describe resourcequota -n wordpress-mysql-app

# Solution: Free up resources or add nodes
```

2. **PVC Not Bound:**
```bash
# Check PVC status
kubectl get pvc -n wordpress-mysql-app

# If pending, check PV
kubectl get pv

# Create or fix PV
kubectl apply -f manifests/storage/pv.yaml
```

3. **Node Selector/Affinity Issues:**
```bash
# Check pod affinity rules
kubectl get pod  -n wordpress-mysql-app -o yaml | grep -A 10 affinity

# Solution: Adjust node labels or remove affinity
```

### Problem: Pod in CrashLoopBackOff

**Symptoms:**
```bash
NAME                         READY   STATUS             RESTARTS   AGE
mysql-xxxxx-xxxxx            0/1     CrashLoopBackOff   5          5m
```

**Diagnosis:**
```bash
# Check logs
kubectl logs mysql-xxxxx-xxxxx -n wordpress-mysql-app

# Check previous logs
kubectl logs mysql-xxxxx-xxxxx -n wordpress-mysql-app --previous

# Describe pod for events
kubectl describe pod mysql-xxxxx-xxxxx -n wordpress-mysql-app
```

**Common Causes and Solutions:**

1. **MySQL Password Issues:**
```bash
# Error: "Access denied for user 'root'"

# Check secret exists
kubectl get secret mysql-pass -n wordpress-mysql-app

# Verify secret content
kubectl get secret mysql-pass -n wordpress-mysql-app -o jsonpath='{.data.password}' | base64 -d

# Recreate secret if needed
kubectl delete secret mysql-pass -n wordpress-mysql-app
kubectl create secret generic mysql-pass --from-literal=password='NewPassword' -n wordpress-mysql-app
kubectl rollout restart deployment mysql -n wordpress-mysql-app
```

2. **Volume Mount Issues:**
```bash
# Error: "Failed to mount volume"

# Check NFS server
showmount -e 

# Test manual mount
sudo mount -t nfs :/mydbdata /mnt
ls /mnt
sudo umount /mnt

# Restart NFS server
ssh worker-node-1 "sudo systemctl restart nfs-kernel-server"
```

3. **Permission Issues:**
```bash
# Error: "Permission denied" in logs

# Fix NFS permissions
ssh worker-node-1 "sudo chmod 777 /mydbdata"
ssh worker-node-1 "sudo chown nobody:nogroup /mydbdata"

# Recreate pod
kubectl delete pod mysql-xxxxx-xxxxx -n wordpress-mysql-app
```

### Problem: Pod Running but Not Ready

**Symptoms:**
```bash
NAME                         READY   STATUS    RESTARTS   AGE
wordpress-xxxxx-xxxxx        0/1     Running   0          5m
```

**Diagnosis:**
```bash
# Check readiness probe
kubectl describe pod wordpress-xxxxx-xxxxx -n wordpress-mysql-app | grep -A 10 "Readiness"

# Check logs
kubectl logs wordpress-xxxxx-xxxxx -n wordpress-mysql-app
```

**Solutions:**

1. **Application Not Starting:**
```bash
# Check if process is running
kubectl exec wordpress-xxxxx-xxxxx -n wordpress-mysql-app -- ps aux

# Check application logs
kubectl logs wordpress-xxxxx-xxxxx -n wordpress-mysql-app --tail=50
```

2. **Database Connection Issues:**
```bash
# Test MySQL connectivity from WordPress pod
kubectl exec wordpress-xxxxx-xxxxx -n wordpress-mysql-app -- nc -zv mysql 3306

# If fails, check MySQL pod
kubectl logs mysql-xxxxx-xxxxx -n wordpress-mysql-app
```

## Service Issues

### Problem: Cannot Access WordPress

**Symptoms:**
- Browser timeout on `http://<node-ip>:30080`
- "Connection refused" error

**Diagnosis:**
```bash
# Check service
kubectl get svc wordpress -n wordpress-mysql-app

# Check endpoints
kubectl get endpoints wordpress -n wordpress-mysql-app

# Check if pods are running
kubectl get pods -l app=wordpress -n wordpress-mysql-app
```

**Solutions:**

1. **Service Not Created:**
```bash
# Apply service
kubectl apply -f manifests/services/wordpress-service.yaml

# Verify service
kubectl describe svc wordpress -n wordpress-mysql-app
```

2. **No Endpoints (No Pods Match Selector):**
```bash
# Check selector
kubectl get svc wordpress -n wordpress-mysql-app -o yaml | grep -A 5 selector

# Check pod labels
kubectl get pods -n wordpress-mysql-app --show-labels

# Fix: Update selector or pod labels
```

3. **Firewall Blocking Port:**
```bash
# Check firewall on node
ssh worker-node-1 "sudo ufw status"

# Allow port
ssh worker-node-1 "sudo ufw allow 30080/tcp"

# Or disable firewall temporarily
ssh worker-node-1 "sudo ufw disable"
```

4. **Test from Within Cluster:**
```bash
# Create test pod
kubectl run test --image=busybox --restart=Never -n wordpress-mysql-app -- sleep 3600

# Test service
kubectl exec test -n wordpress-mysql-app -- wget -O- http://wordpress

# If works, issue is external access
```

### Problem: WordPress Cannot Connect to MySQL

**Symptoms:**
- WordPress shows "Error establishing database connection"
- Logs show connection failures

**Diagnosis:**
```bash
# Check MySQL service
kubectl get svc mysql -n wordpress-mysql-app

# Check MySQL pod
kubectl get pods -l app=mysql -n wordpress-mysql-app

# Test DNS resolution
kubectl exec  -n wordpress-mysql-app -- nslookup mysql
```

**Solutions:**

1. **MySQL Service Not Found:**
```bash
# Apply MySQL service
kubectl apply -f manifests/services/mysql-service.yaml
```

2. **MySQL Pod Not Running:**
```bash
# Check MySQL pod logs
kubectl logs -l app=mysql -n wordpress-mysql-app

# Restart MySQL deployment
kubectl rollout restart deployment mysql -n wordpress-mysql-app
```

3. **Wrong Credentials:**
```bash
# Verify secret
kubectl get secret mysql-pass -n wordpress-mysql-app -o jsonpath='{.data.password}' | base64 -d

# Update WordPress to use correct password
kubectl rollout restart deployment wordpress -n wordpress-mysql-app
```

4. **Network Policy Blocking:**
```bash
# Check network policies
kubectl get networkpolicies -n wordpress-mysql-app

# Temporarily delete to test
kubectl delete networkpolicy  -n wordpress-mysql-app
```

## Storage Issues

### Problem: PVC Stuck in Pending

**Symptoms:**
```bash
NAME        STATUS    VOLUME   CAPACITY   ACCESS MODES   AGE
mysql-pvc   Pending                                      5m
```

**Diagnosis:**
```bash
# Describe PVC
kubectl describe pvc mysql-pvc -n wordpress-mysql-app

# Check PVs
kubectl get pv

# Check storage classes
kubectl get storageclass
```

**Solutions:**

1. **No Matching PV:**
```bash
# Create PV
kubectl apply -f manifests/storage/pv.yaml

# Verify PV
kubectl get pv mysql-pv
```

2. **Selector Mismatch:**
```bash
# Check PVC selector
kubectl get pvc mysql-pvc -n wordpress-mysql-app -o yaml | grep -A 5 selector

# Check PV labels
kubectl get pv mysql-pv -o yaml | grep -A 5 labels

# Ensure labels match
```

3. **Access Mode Mismatch:**
```bash
# Check PVC access modes
kubectl get pvc mysql-pvc -n wordpress-mysql-app -o yaml | grep accessModes

# Check PV access modes
kubectl get pv mysql-pv -o yaml | grep accessModes

# Must be compatible (e.g., both ReadWriteMany)
```

### Problem: NFS Mount Failures

**Symptoms:**
- Pod logs show "mount: mounting failed"
- Events show "Unable to attach or mount volumes"

**Diagnosis:**
```bash
# Check NFS server
ssh worker-node-1 "sudo systemctl status nfs-kernel-server"

# Check exports
ssh worker-node-1 "sudo exportfs -v"

# Test from client
showmount -e 
```

**Solutions:**

1. **NFS Server Not Running:**
```bash
# Start NFS server
ssh worker-node-1 "sudo systemctl start nfs-kernel-server"
ssh worker-node-1 "sudo systemctl enable nfs-kernel-server"
```

2. **Export Not Configured:**
```bash
# Add export
ssh worker-node-1 "echo '/mydbdata  *(rw,sync,no_root_squash)' | sudo tee -a /etc/exports"
ssh worker-node-1 "sudo exportfs -rv"
```

3. **NFS Client Not Installed:**
```bash
# Install on worker nodes
ssh worker-node-2 "sudo apt install -y nfs-common"
```

4. **Firewall Blocking NFS:**
```bash
# Allow NFS ports
ssh worker-node-1 "sudo ufw allow from  to any port 2049"
ssh worker-node-1 "sudo ufw allow from  to any port 111"
```

## Configuration Issues

### Problem: ConfigMap or Secret Not Found

**Symptoms:**
- Pod logs show "secret 'mysql-pass' not found"
- Pod events show "MountVolume.SetUp failed"

**Diagnosis:**
```bash
# Check secret
kubectl get secret mysql-pass -n wordpress-mysql-app

# Check configmap
kubectl get configmap wordpress-config -n wordpress-mysql-app
```

**Solutions:**

1. **Create Missing Secret:**
```bash
kubectl create secret generic mysql-pass \
  --from-literal=password='YourPassword' \
  -n wordpress-mysql-app
```

2. **Create Missing ConfigMap:**
```bash
kubectl apply -f manifests/configmap/wordpress-config.yaml
```

3. **Restart Deployment:**
```bash
kubectl rollout restart deployment wordpress -n wordpress-mysql-app
kubectl rollout restart deployment mysql -n wordpress-mysql-app
```

## Performance Issues

### Problem: Slow Response Times

**Diagnosis:**
```bash
# Check resource usage
kubectl top pods -n wordpress-mysql-app
kubectl top nodes

# Check pod resource limits
kubectl describe pod  -n wordpress-mysql-app | grep -A 10 "Limits"
```

**Solutions:**

1. **Insufficient Resources:**
```bash
# Increase limits in deployment
kubectl edit deployment wordpress -n wordpress-mysql-app

# Update resources section:
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

2. **Database Performance:**
```bash
# Check MySQL slow query log
kubectl exec  -n wordpress-mysql-app -- mysql -uroot -p -e "SHOW VARIABLES LIKE 'slow_query%';"

# Optimize database
kubectl exec  -n wordpress-mysql-app -- mysql -uroot -p database1 -e "OPTIMIZE TABLE wp_posts, wp_postmeta;"
```

3. **Storage I/O:**
```bash
# Check NFS server load
ssh worker-node-1 "iostat -x 1 5"

# Consider using local volumes or faster storage
```

## Dashboard Issues

### Problem: Cannot Access Dashboard

**Diagnosis:**
```bash
# Check dashboard pods
kubectl get pods -n kubernetes-dashboard

# Check dashboard service
kubectl get svc -n kubernetes-dashboard
```

**Solutions:**

1. **Dashboard Not Installed:**
```bash
cd dashboard
./dashboard-setup.sh
```

2. **Token Expired:**
```bash
# Create new token
kubectl -n kubernetes-dashboard create token admin-user
```

3. **Proxy Not Running:**
```bash
# Start proxy
kubectl proxy

# Access at: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

## Cleanup and Reset

### Complete Reset

**Warning: This deletes all data!**

```bash
# Run cleanup script
cd scripts
./cleanup.sh

# Or manual cleanup:
kubectl delete namespace wordpress-mysql-app
kubectl delete pv mysql-pv
ssh worker-node-1 "sudo rm -rf /mydbdata/*"
```

### Partial Reset

**Reset pods only:**
```bash
kubectl rollout restart deployment mysql wordpress -n wordpress-mysql-app
```

**Reset database only:**
```bash
kubectl delete pod -l app=mysql -n wordpress-mysql-app
ssh worker-node-1 "sudo rm -rf /mydbdata/*"
```

## Getting Help

### Collect Debug Information

```bash
# Create debug bundle
kubectl cluster-info dump --output-directory=/tmp/k8s-debug --namespace wordpress-mysql-app

# Get all resource definitions
kubectl get all -n wordpress-mysql-app -o yaml > /tmp/resources.yaml

# Get events
kubectl get events -n wordpress-mysql-app --sort-by='.lastTimestamp' > /tmp/events.txt

# Get logs
kubectl logs -l app=mysql -n wordpress-mysql-app > /tmp/mysql.log
kubectl logs -l app=wordpress -n wordpress-mysql-app > /tmp/wordpress.log
```

### Common kubectl Commands

```bash
# Get pod logs
kubectl logs  -n wordpress-mysql-app

# Execute command in pod
kubectl exec -it  -n wordpress-mysql-app -- /bin/bash

# Port forward for testing
kubectl port-forward  8080:80 -n wordpress-mysql-app

# Describe resource
kubectl describe   -n wordpress-mysql-app

# Get resource YAML
kubectl get   -n wordpress-mysql-app -o yaml

# Watch resources
kubectl get pods -n wordpress-mysql-app --watch
```

---

**Last Updated**: October 2025  
**Version**: 1.0.0
