# Architecture Documentation

## System Architecture Overview

This document describes the architecture of the WordPress and MySQL deployment on Kubernetes with NFS-based persistent storage.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                       │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Namespace: wordpress-mysql-app            │  │
│  │                                                         │  │
│  │  ┌──────────────────┐         ┌──────────────────┐   │  │
│  │  │   WordPress      │────────▶│     MySQL        │   │  │
│  │  │   Deployment     │         │   Deployment     │   │  │
│  │  │                  │         │                  │   │  │
│  │  │  Replicas: 1     │         │  Replicas: 1     │   │  │
│  │  │  Image: WP 4.8   │         │  Image: MySQL5.6 │   │  │
│  │  │  Port: 80        │         │  Port: 3306      │   │  │
│  │  └────────┬─────────┘         └────────┬─────────┘   │  │
│  │           │                             │             │  │
│  │           │                             │             │  │
│  │  ┌────────▼─────────┐         ┌────────▼─────────┐   │  │
│  │  │  WordPress Svc   │         │   MySQL Svc      │   │  │
│  │  │  Type: NodePort  │         │  Type: ClusterIP │   │  │
│  │  │  Port: 30080     │         │  Port: 3306      │   │  │
│  │  └──────────────────┘         └──────────────────┘   │  │
│  │                                         │             │  │
│  │                                         │             │  │
│  │                                ┌────────▼─────────┐   │  │
│  │                                │  PVC: mysql-pvc  │   │  │
│  │                                │  Size: 5Gi       │   │  │
│  │                                └────────┬─────────┘   │  │
│  └─────────────────────────────────────────┼─────────────┘  │
│                                             │                │
│  ┌──────────────────────────────────────────▼─────────────┐ │
│  │              PV: mysql-pv (NFS-backed)                  │ │
│  │              Size: 5Gi                                  │ │
│  └──────────────────────────────────────────┬──────────────┘ │
└─────────────────────────────────────────────┼────────────────┘
                                              │
                                              │ NFS Mount
                                              │
                                   ┌──────────▼──────────┐
                                   │   Worker Node 1     │
                                   │   NFS Server        │
                                   │   /mydbdata         │
                                   └─────────────────────┘
```

## Component Details

### 1. Application Layer

#### WordPress Deployment
- **Purpose**: Frontend web application
- **Image**: wordpress:4.8-apache
- **Replicas**: 1 (scalable)
- **Resource Limits**:
  - Memory: 256Mi-512Mi
  - CPU: 200m-400m
- **Environment Variables**:
  - `WORDPRESS_DB_HOST`: mysql:3306
  - `WORDPRESS_DB_PASSWORD`: From Secret
  - `WORDPRESS_SITE_TITLE`: From ConfigMap
  - `WORDPRESS_ADMIN_EMAIL`: From ConfigMap

#### MySQL Deployment
- **Purpose**: Backend database
- **Image**: mysql:5.6
- **Replicas**: 1 (single instance)
- **Strategy**: Recreate (prevents multiple instances)
- **Resource Limits**:
  - Memory: 512Mi-1Gi
  - CPU: 250m-500m
- **Environment Variables**:
  - `MYSQL_ROOT_PASSWORD`: From Secret
  - `MYSQL_DATABASE`: database1
- **Persistent Storage**: Mounted at /var/lib/mysql

### 2. Network Layer

#### WordPress Service
- **Type**: NodePort
- **Purpose**: External access to WordPress
- **Ports**:
  - Internal: 80
  - NodePort: 30080
- **Selector**: app=wordpress, tier=frontend

#### MySQL Service
- **Type**: ClusterIP (default)
- **Purpose**: Internal database access
- **Port**: 3306
- **Selector**: app=mysql
- **Note**: Only accessible within cluster

### 3. Storage Layer

#### NFS Server (Worker Node 1)
- **Location**: /mydbdata
- **Export Options**: rw,sync,no_root_squash
- **Permissions**: 777 (nobody:nogroup)
- **Purpose**: Centralized persistent storage

#### Persistent Volume (PV)
- **Name**: mysql-pv
- **Type**: NFS
- **Capacity**: 5Gi
- **Access Mode**: ReadWriteMany
- **Reclaim Policy**: Retain
- **Labels**: type=nfs

#### Persistent Volume Claim (PVC)
- **Name**: mysql-pvc
- **Namespace**: wordpress-mysql-app
- **Request**: 5Gi
- **Access Mode**: ReadWriteMany
- **Selector**: Matches PV with label type=nfs

### 4. Configuration Layer

#### ConfigMap: wordpress-config
- **Purpose**: Non-sensitive WordPress configuration
- **Data**:
  - WORDPRESS_SITE_TITLE: "My Blog"
  - WORDPRESS_ADMIN_EMAIL: "admin@example.com"

#### Secret: mysql-pass
- **Purpose**: Secure storage of MySQL password
- **Type**: Opaque
- **Key**: password
- **Note**: Base64 encoded, accessed via environment variables

### 5. Resource Management

#### ResourceQuota
- **Purpose**: Limit resource consumption
- **Limits**:
  - CPU Requests: 2 cores
  - CPU Limits: 4 cores
  - Memory Requests: 2Gi
  - Memory Limits: 4Gi
  - PVCs: 5
  - Pods: 10

#### LimitRange
- **Purpose**: Default and boundary limits for containers
- **Container Limits**:
  - Max CPU: 1 core
  - Min CPU: 100m
  - Max Memory: 1Gi
  - Min Memory: 128Mi
  - Default CPU: 500m
  - Default Memory: 512Mi

## Data Flow

### WordPress Installation Flow

1. User accesses `http://<NODE-IP>:30080`
2. Request hits NodePort service on any node
3. kube-proxy routes to WordPress pod
4. WordPress pod serves HTTP response
5. User completes WordPress setup wizard

### Database Connection Flow

1. WordPress pod resolves `mysql` service via DNS
2. Connection routed to MySQL ClusterIP service
3. Service forwards to MySQL pod on port 3306
4. MySQL authenticates using password from Secret
5. WordPress connects to `database1` database

### Data Persistence Flow

1. MySQL writes data to /var/lib/mysql (container)
2. Volume mount maps to PVC (mysql-pvc)
3. PVC is bound to PV (mysql-pv)
4. PV uses NFS to write to worker-node-1:/mydbdata
5. Data persists even if MySQL pod restarts

## Security Architecture

### Network Security
- MySQL only accessible via ClusterIP (internal)
- WordPress exposed via NodePort (controlled external access)
- No direct external access to MySQL

### Secret Management
- Passwords stored in Kubernetes Secrets
- Secrets mounted as environment variables
- Base64 encoded (encrypted at rest if configured)

### RBAC (Dashboard)
- ServiceAccount: admin-user
- ClusterRoleBinding: cluster-admin role
- Token-based authentication

### File Permissions
- NFS directory: 777 (for demonstration; restrict in production)
- Owner: nobody:nogroup (prevents privilege escalation)

## Scalability Considerations

### Horizontal Scaling

**WordPress (Supported)**:
```bash
kubectl scale deployment wordpress --replicas=3 -n wordpress-mysql-app
```
- Multiple WordPress pods can share the same MySQL instance
- NodePort service load-balances across pods

**MySQL (Limited)**:
- Current setup: Single instance (Recreate strategy)
- For production: Consider MySQL replication or managed services
- StatefulSet would be needed for multi-instance MySQL

### Vertical Scaling

Adjust resource limits in deployment manifests:
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

## High Availability

### Current Limitations
- Single MySQL instance (SPOF)
- NFS server on single node (SPOF)
- No redundancy for storage

### Production Recommendations
1. **Database**: 
   - MySQL replication (Master-Slave)
   - Managed database service (RDS, CloudSQL)
   - StatefulSet for MySQL cluster

2. **Storage**:
   - Replicated storage solution (Ceph, GlusterFS)
   - Cloud-based persistent disks
   - Database backups to S3/GCS

3. **Application**:
   - Multiple WordPress replicas
   - Session persistence (Redis/Memcached)
   - Load balancer with health checks

## Monitoring and Observability

### Recommended Tools
- **Metrics**: Prometheus + Grafana
- **Logging**: EFK Stack (Elasticsearch, Fluentd, Kibana)
- **Tracing**: Jaeger or Zipkin
- **Dashboard**: Kubernetes Dashboard (already included)

### Key Metrics to Monitor
- Pod CPU/Memory usage
- PVC usage and IOPS
- Service latency and error rates
- NFS server performance
- Database query performance

## Disaster Recovery

### Backup Strategy
1. **Database Backups**:
   - Regular mysqldump exports
   - Store in external storage (S3, GCS)
   - Automated with CronJobs

2. **Volume Snapshots**:
   - NFS directory backups
   - Incremental backups recommended

3. **Configuration Backups**:
   - YAML manifests in Git
   - ConfigMaps and Secrets in secure storage

### Recovery Procedure
1. Restore NFS data from backup
2. Apply all Kubernetes manifests
3. Import database backup if needed
4. Verify application functionality

## Performance Optimization

### Database
- Tune MySQL configuration (my.cnf)
- Index optimization
- Query caching
- Connection pooling

### Application
- WordPress caching plugins
- CDN for static assets
- Object caching (Redis/Memcached)
- PHP opcode caching

### Storage
- SSD-backed storage for database
- Separate volumes for database and application
- Monitor I/O wait times

## Deployment Strategies

### Rolling Updates
WordPress supports rolling updates:
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

### Blue-Green Deployment
For major updates:
1. Deploy new version alongside old
2. Test new version
3. Switch traffic
4. Remove old version

### Canary Deployment
Gradual rollout to subset of users:
1. Deploy new version with few replicas
2. Monitor metrics
3. Gradually increase replicas
4. Replace old version

## Cost Optimization

### Resource Sizing
- Right-size CPU/memory requests
- Use limits to prevent resource exhaustion
- Monitor actual usage patterns

### Storage
- Delete unused PVCs
- Implement storage lifecycle policies
- Compress backups

### Node Utilization
- Use node affinity for efficient placement
- Consider spot/preemptible instances
- Implement cluster autoscaling

## Compliance and Governance

### Data Protection
- Encrypt data at rest (PV encryption)
- Encrypt data in transit (TLS)
- Regular security patches

### Access Control
- RBAC for namespace isolation
- Network policies for traffic control
- Audit logging enabled

### Policy Enforcement
- Pod Security Policies
- Resource quotas per namespace
- Image scanning and signing
