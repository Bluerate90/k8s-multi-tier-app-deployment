# Prerequisites Guide

## System Requirements

### Kubernetes Cluster

#### Minimum Requirements
- **Kubernetes Version**: 1.20 or higher
- **Nodes**: 
  - 1 Master node (control plane)
  - 2 Worker nodes (minimum)
- **Container Runtime**: Docker, containerd, or CRI-O

#### Master Node
- **CPU**: 2 cores
- **RAM**: 2GB
- **Disk**: 20GB
- **OS**: Ubuntu 18.04+, Debian 10+, CentOS 7+, or RHEL 7+

#### Worker Nodes
- **CPU**: 2 cores (per node)
- **RAM**: 4GB (per node)
- **Disk**: 20GB (per node)
- **OS**: Ubuntu 18.04+, Debian 10+, CentOS 7+, or RHEL 7+

### Network Requirements

#### Ports
| Port | Protocol | Purpose | Source | Destination |
|------|----------|---------|--------|-------------|
| 6443 | TCP | Kubernetes API | External | Master |
| 2379-2380 | TCP | etcd | Master | Master |
| 10250 | TCP | Kubelet API | Master | Worker |
| 10251 | TCP | kube-scheduler | Master | Master |
| 10252 | TCP | kube-controller | Master | Master |
| 30080 | TCP | WordPress | External | Worker |
| 2049 | TCP/UDP | NFS | Worker | Worker |
| 111 | TCP/UDP | RPC | Worker | Worker |

#### Network Plugin
- Calico, Flannel, Weave, or any CNI plugin
- Pod network CIDR configured
- Service network CIDR configured

### Storage Requirements

#### NFS Server (Worker Node 1)
- **Available Space**: 20GB minimum
- **Filesystem**: ext4 or xfs recommended
- **Mount Point**: /mydbdata
- **Permissions**: Read/Write for nobody:nogroup

#### Database Storage (via NFS)
- **MySQL Data**: ~5GB (configurable)
- **Growth**: Plan for data growth over time

## Software Requirements

### Required Tools

#### kubectl
```bash
# Version check
kubectl version --client

# Minimum version: 1.20
```

#### NFS Utilities

**Ubuntu/Debian:**
```bash
# Server
nfs-kernel-server

# Client
nfs-common
```

**CentOS/RHEL:**
```bash
# Server
nfs-utils

# Client
nfs-utils
```

### Optional Tools

#### Helm (Package Manager)
```bash
# Version 3.x recommended
helm version
```

#### kubectx/kubens (Context Management)
```bash
# Switch contexts easily
kubectx
kubens
```

#### k9s (Terminal UI)
```bash
# Interactive cluster management
k9s
```

## Access Requirements

### Cluster Access
- kubeconfig file properly configured
- Valid certificates and tokens
- Network connectivity to cluster

### Node Access
- SSH access to all nodes
- Sudo privileges for installation
- Key-based authentication recommended

### External Access
- Access to worker node IPs
- Port 30080 accessible from client machine
- DNS resolution (if using domain names)

## Skill Prerequisites

### Required Knowledge
- Basic Kubernetes concepts (Pods, Services, Deployments)
- Linux command line
- Basic networking concepts
- YAML syntax

### Recommended Knowledge
- Container concepts (Docker)
- NFS configuration
- MySQL administration
- WordPress administration

## Pre-Installation Checklist

### Before Starting

- [ ] Kubernetes cluster is running
- [ ] kubectl is installed and configured
- [ ] Can access all nodes via SSH
- [ ] Firewall rules allow required ports
- [ ] NFS packages can be installed
- [ ] Sufficient disk space on worker-node-1
- [ ] Have decided on MySQL root password
- [ ] Network plugin is functioning
- [ ] DNS resolution working in cluster

### Verification Commands

```bash
# Check cluster status
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check network connectivity
kubectl run test-pod --image=busybox --restart=Never --rm -it -- ping -c 3 8.8.8.8

# Check DNS
kubectl run test-dns --image=busybox --restart=Never --rm -it -- nslookup kubernetes.default

# Check storage classes
kubectl get storageclass

# Check API server
kubectl get --raw /healthz

# Test SSH to nodes
ssh user@worker-node-1 "echo 'SSH working'"
ssh user@worker-node-2 "echo 'SSH working'"
```

## Environment-Specific Considerations

### Cloud Providers

#### AWS
- Use EBS for persistent storage (alternative to NFS)
- Security groups for port access
- IAM roles for permissions
- Consider using RDS for MySQL

#### GCP
- Use Persistent Disks (alternative to NFS)
- Firewall rules for port access
- Service accounts for permissions
- Consider using Cloud SQL for MySQL

#### Azure
- Use Azure Disks (alternative to NFS)
- NSG rules for port access
- Managed identities for permissions
- Consider using Azure Database for MySQL

### On-Premises

#### Bare Metal
- Ensure hardware compatibility
- Configure network properly
- Setup load balancer for high availability
- Plan for storage redundancy

#### Virtual Machines
- Allocate sufficient resources
- Configure network bridging
- Setup snapshots for backups
- Plan for VM migration

## Troubleshooting Prerequisites

### Common Issues

**kubectl not working:**
```bash
# Set KUBECONFIG
export KUBECONFIG=$HOME/.kube/config

# Check permissions
chmod 600 $HOME/.kube/config

# Verify context
kubectl config current-context
```

**Node not ready:**
```bash
# Check node status
kubectl describe node 

# Check kubelet
sudo systemctl status kubelet

# Check logs
sudo journalctl -u kubelet -f
```

**Network issues:**
```bash
# Check CNI plugin
kubectl get pods -n kube-system | grep -i calico

# Test pod-to-pod communication
kubectl run test1 --image=busybox --restart=Never -- sleep 3600
kubectl run test2 --image=busybox --restart=Never -- sleep 3600
kubectl exec test1 -- ping $(kubectl get pod test2 -o jsonpath='{.status.podIP}')
```

## Security Considerations

### Before Deployment

- [ ] Review security policies
- [ ] Plan secret management strategy
- [ ] Configure network policies
- [ ] Setup RBAC properly
- [ ] Enable audit logging
- [ ] Plan backup strategy
- [ ] Configure monitoring

### Hardening Steps

```bash
# Enable pod security policies
kubectl apply -f pod-security-policy.yaml

# Create network policies
kubectl apply -f network-policies.yaml

# Configure RBAC
kubectl apply -f rbac-config.yaml

# Enable audit logging
# (Configure on API server)
```

## Post-Installation Requirements

### Monitoring

- [ ] Setup Prometheus for metrics
- [ ] Configure Grafana dashboards
- [ ] Setup alerting rules
- [ ] Configure log aggregation

### Backup

- [ ] Schedule database backups
- [ ] Test restore procedures
- [ ] Document recovery steps
- [ ] Store backups securely

### Maintenance

- [ ] Plan update schedule
- [ ] Document procedures
- [ ] Setup maintenance windows
- [ ] Create runbooks

---

**Last Updated**: October 2025  
**Version**: 1.0.0
