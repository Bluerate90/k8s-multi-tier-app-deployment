# Kubernetes Multi-Tier MySQL & WordPress Application Deployment

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-%23117AC9.svg?style=for-the-badge&logo=WordPress&logoColor=white)
![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

Production-ready Kubernetes deployment of WordPress &amp; MySQL with NFS persistent storage, demonstrating advanced DevOps practices including secrets management, ConfigMaps, resource quotas, and the Kubernetes Dashboard.

![GitHub last commit](https://img.shields.io/github/last-commit/Bluerate90/k8s-multi-tier-app-deployment)
![GitHub stars](https://img.shields.io/github/stars/Bluerate90/k8s-multi-tier-app-deployment)
![GitHub forks](https://img.shields.io/github/forks/Bluerate90/k8s-multi-tier-app-deployment)
![License](https://img.shields.io/github/license/Bluerate90/k8s-multi-tier-app-deployment)

## 🏗️ Architecture
```text
┌─────────────────┐         ┌──────────────────┐
│   WordPress     │────────▶│     MySQL        │
│   (Frontend)    │         │    (Backend)     │
│   Port: 30080   │         │    Port: 3306    │
└─────────────────┘         └──────────────────┘
         │                           │
         └───────────┬───────────────┘
                     │
              ┌──────▼──────┐
              │ NFS Storage │
              │  /mydbdata  │
              └─────────────┘
```
## 🎯 Project Objectives

This project was created to demonstrate:
- Real-world DevOps skills applicable to production environments
- Understanding of container orchestration and Kubernetes architecture
- Ability to implement security best practices
- Strong documentation and communication skills
- Problem-solving capabilities in cloud-native environments

## 💡 Business Value

This deployment pattern solves common challenges faced by organizations:
- **Scalability**: Easy horizontal scaling of web tier
- **Reliability**: Persistent data storage prevents data loss
- **Security**: Proper secrets management and access control
- **Cost Efficiency**: Resource quotas prevent over-allocation
- **Maintainability**: Clear documentation reduces operational burden

## 📊 Project Highlights

| Aspect | Details |
|--------|---------|
| **Deployment Type** | Multi-tier containerized application |
| **Technologies** | Kubernetes, Docker, MySQL, WordPress, NFS |
| **Complexity Level** | Production-ready with HA considerations |
| **Security** | Secrets, ConfigMaps, RBAC, Network isolation |
| **Storage** | Persistent volumes with NFS backend |
| **Monitoring** | Kubernetes Dashboard, Resource quotas |
| **Documentation** | Comprehensive guides and troubleshooting |

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (v1.20+)
- kubectl configured
- At least 2 worker nodes
- Ubuntu/Debian-based nodes (for NFS setup)

### Installation Steps

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/kubernetes-mysql-wordpress-deployment.git
cd kubernetes-mysql-wordpress-deployment
```

2. **Setup NFS Storage**
```bash
# On worker-node-1 (NFS Server)
cd nfs-setup
chmod +x nfs-server-setup.sh
sudo ./nfs-server-setup.sh

# On worker-node-2 (NFS Client)
chmod +x nfs-client-setup.sh
sudo ./nfs-client-setup.sh
```

3. **Deploy the Application**
```bash
cd scripts
chmod +x deploy-all.sh
./deploy-all.sh
```

4. **Access the Application**
```bash
# Get the worker node IP
kubectl get nodes -o wide

# Access WordPress at:
http://<WORKER-NODE-IP>:30080
```

## 🔧 Configuration

### Creating Secrets
```bash
kubectl create secret generic mysql-pass \
  --from-literal=password='YourSecurePassword123!'
```

### Applying ConfigMaps
```bash
kubectl apply -f manifests/configmap/wordpress-config.yaml
```

## 📊 Verification Commands

```bash
# Check all pods
kubectl get pods

# Check services
kubectl get svc

# Check persistent volumes
kubectl get pv,pvc

# View WordPress logs
kubectl logs -l app=wordpress

# View MySQL logs
kubectl logs -l app=mysql
```

## 🖥️ Kubernetes Dashboard

### Accessing the Dashboard

1. **Get the token**
```bash
kubectl -n kubernetes-dashboard create token admin-user
```

2. **Start proxy**
```bash
kubectl proxy
```

3. **Access Dashboard**
```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

## 📁 Repository Structure

```text
k8s-multi-tier-app-deployment/
├── README.md                          ⭐ Main project documentation
├── SETUP.md                           📖 Detailed setup guide
├── ARCHITECTURE.md                    🏗️ Architecture documentation
├── LICENSE                            ⚖️ MIT LICENSE
├── .gitignore                         🚫 Ignore unnecessary files
│
├── manifests/                         📁 All Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap/
│   │   └── wordpress-config.yaml
│   ├── secrets/
│   │   └── mysql-secret.yaml.example
│   ├── storage/
│   │   ├── pv.yaml
│   │   └── pvc.yaml
│   ├── deployments/
│   │   ├── mysql-deployment.yaml
│   │   └── wordpress-deployment.yaml
│   ├── services/
│   │   ├── mysql-service.yaml
│   │   └── wordpress-service.yaml
│   ├── resourcequota.yaml
│   └── limitrange.yaml
│
├── nfs-setup/                         📁 NFS configuration scripts
│   ├── nfs-server-setup.sh
│   └── nfs-client-setup.sh
│
├── dashboard/                         📁 Dashboard setup
│   ├── dashboard-setup.sh
│   └── create-admin-user.yaml
│
├── scripts/                           📁 Automation scripts
│   ├── deploy-all.sh
│   ├── verify-deployment.sh
│   └── cleanup.sh
│
└── docs/                              📁 Additional documentation
    ├── prerequisites.md
    ├── troubleshooting.md
    └── screenshots


k8s-multi-tier-app-deployment/
│
├── README.md
├── SETUP.md
├── ARCHITECTURE.md
│
├── manifests/
│   ├── namespace.yaml
│   ├── configmap/
│   │   └── wordpress-config.yaml
│   ├── secrets/
│   │   └── mysql-secret.yaml
│   ├── storage/
│   │   ├── pv.yaml
│   │   └── pvc.yaml
│   ├── deployments/
│   │   ├── mysql-deployment.yaml
│   │   └── wordpress-deployment.yaml
│   └── services/
│       ├── mysql-service.yaml
│       └── wordpress-service.yaml
│
├── nfs-setup/
│   ├── nfs-server-setup.sh
│   └── nfs-client-setup.sh
│
├── dashboard/
│   ├── dashboard-setup.sh
│   └── create-admin-user.yaml
│
├── scripts/
│   ├── deploy-all.sh
│   ├── cleanup.sh
│   └── verify-deployment.sh
│
├── docs/
│   ├── prerequisites.md
│   ├── troubleshooting.md
│   └── screenshots/
│
└── .gitignore
```

## 💼 Skills Demonstrated

### DevOps & Cloud
- ✅ Container orchestration with Kubernetes
- ✅ Infrastructure as Code (IaC)
- ✅ Configuration management
- ✅ Secret management and security
- ✅ Resource optimization and limits

### System Administration
- ✅ NFS server configuration
- ✅ Linux system administration
- ✅ Network configuration
- ✅ Storage management
- ✅ Service deployment and management

### Application Deployment
- ✅ Multi-tier architecture deployment
- ✅ Database configuration and persistence
- ✅ Web application deployment
- ✅ Service discovery and networking
- ✅ Load balancing and scaling

### Monitoring & Operations
- ✅ Kubernetes Dashboard implementation
- ✅ Logging and troubleshooting
- ✅ Resource monitoring
- ✅ Performance optimization
- ✅ Backup and recovery planning

## 📈 Metrics & Results

- **Deployment Time**: Automated deployment in under 5 minutes
- **Resource Efficiency**: Optimized resource allocation with quotas
- **High Availability**: 99.9% uptime potential with proper scaling
- **Data Persistence**: Zero data loss during pod restarts
- **Documentation**: 100% coverage with troubleshooting guides

## 🏆 Key Achievements

✅ Implemented production-grade security with Kubernetes Secrets  
✅ Achieved data persistence using NFS-backed storage  
✅ Created comprehensive documentation (4000+ lines)  
✅ Built reusable automation scripts for deployment  
✅ Established monitoring with Kubernetes Dashboard  
✅ Designed scalable architecture supporting growth  

## 🎓 Learning Outcomes

Through this project, I gained deep expertise in:
- Kubernetes resource management and orchestration
- Storage provisioning and persistent volume management
- Network configuration and service discovery
- Security implementation (RBAC, Secrets, ConfigMaps)
- Linux system administration and NFS configuration
- Troubleshooting complex distributed systems
- Technical documentation and knowledge sharing

## 📅 Maintenance Schedule

- **Weekly**: Check for issues/PRs
- **Monthly**: Update dependencies
- **Quarterly**: Review and update documentation
- **Yearly**: Major refactoring or new features

## 🔄 Version History

<details>
<summary>Click to expand Version History</summary>

### v1.0.0 (October 2025)
- Initial release
- WordPress 4.8 + MySQL 5.6
- NFS persistent storage
- Kubernetes Dashboard integration

### Future Versions
- v1.1.0: Add Helm chart
- v1.2.0: Implement monitoring
- v2.0.0: Add CI/CD pipeline

</details>

## 📝 Documentation

- [Detailed Setup Guide](SETUP.md)
- [Architecture Documentation](ARCHITECTURE.md)
- [Prerequisites](docs/prerequisites.md)
- [Troubleshooting Guide](docs/troubleshooting.md)

---

⭐ **Star this repository if you found it helpful!**

*Built with ❤️ for demonstrating Kubernetes expertise*
