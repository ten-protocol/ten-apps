# Ten Protocol Infrastructure Apps

## Overview

This repository contains the Kubernetes deployment infrastructure for **Ten Protocol** , a privacy-focused Layer 2 blockchain network. The project uses **Helm charts** and **ArgoCD GitOps** to deploy and manage various components of the Ten ecosystem across multiple environments.

## 🏗️ Architecture

### Core Components
- **🔐 Enclave**: TEE (Trusted Execution Environment) running in Intel SGX hardware
- **🌐 Host**: Layer 2 blockchain node with P2P networking and RPC interfaces  
- **💾 EdgelessDB**: Confidential database for secure data storage
- **🔍 TenScan**: Block explorer for transparency and network visibility
- **💧 Faucet**: Test token distribution service for developers
- **🌉 Bridge**: Cross-chain asset transfer interface

### Infrastructure Stack
- **Kubernetes**: Container orchestration platform
- **Helm**: Package manager for Kubernetes applications
- **ArgoCD**: GitOps continuous deployment
- **Azure Container Registry**: Container image storage
- **Intel SGX**: Trusted execution environment for privacy

## 📁 Repository Structure

```
ten-apps/
├── charts/                              # Helm Charts
│   ├── ten-node/                       # Core Ten Protocol node
│   │   ├── templates/                  # Kubernetes manifests
│   │   ├── values.yaml                 # Default configuration
│   │   └── README.md                   # Chart documentation
│   ├── ten-tools/                      # Supporting services
│   │   ├── templates/                  # TenScan, Faucet, Bridge
│   │   ├── values.yaml                 # Tool configurations
│   │   └── README.md                   # Tools documentation
│   ├── ten-gateway/                    # Gateway services
│   └── ten-clean-node/                 # Clean deployment variant
│
├── nonprod-argocd-config/              # GitOps Configuration
│   └── apps/                           # ArgoCD Applications
│       ├── root-app.yaml               # Root app-of-apps
│       ├── uat-apps.yaml               # UAT environment
│       ├── sepolia-apps.yaml           # Sepolia testnet
│       ├── dev-apps.yaml               # Development
│       └── envs/                       # Environment-specific configs
│           ├── uat/                    # UAT configurations
│           ├── sepolia/                # Sepolia configurations
│           └── dev/                    # Development configurations
│
├── README.md                           # This file
├── ARGOCD-DEPLOYMENT-PATTERN.md        # GitOps architecture guide
└── .git/                               # Git repository
```

## 🚀 Quick Start

### Prerequisites
- **Kubernetes cluster** with Intel SGX support
- **ArgoCD** installed and configured
- **Helm 3.0+** for local chart management
- **kubectl** configured for cluster access

### 1. Setup SGX Nodes
```bash
# Label SGX-capable nodes
kubectl label nodes <sgx-node-1> sgx-capable=true
kubectl label nodes <sgx-node-2> sgx-capable=true

# Taint nodes for dedicated SGX workloads (optional)
kubectl taint nodes <sgx-node-1> sgx=dedicated:NoSchedule
kubectl taint nodes <sgx-node-2> sgx=dedicated:NoSchedule
```

### 2. Deploy via ArgoCD (Recommended)
```bash
# Deploy environment-specific app-of-apps
kubectl apply -f nonprod-argocd-config/apps/uat-apps.yaml

# Monitor deployment status
argocd app list
argocd app sync ten-uat-apps
```

### 3. Manual Helm Deployment (Development)
```bash
# Deploy Ten Protocol node
helm install ten-node ./charts/ten-node \
  --namespace ten-protocol \
  --create-namespace \
  -f values-production.yaml

# Deploy supporting tools
helm install ten-tools ./charts/ten-tools \
  --namespace ten-tools \
  --create-namespace
```

## 🌍 Environment Management

### Supported Environments
| Environment | Purpose | Sync Policy | Namespace |
|-------------|---------|-------------|-----------|
| **UAT** | User Acceptance Testing | Manual | `uat` |
| **Sepolia** | Ethereum Testnet | Automated | `sepolia` |
| **Dev** | Development & Testing | Automated | `dev` |

### Environment-Specific Configuration
```yaml
# UAT Environment Values
enclave:
  nodeSelector:
    kubernetes.io/hostname: "aks-sgxpool2-vmss000005"
host:
  fqdn: "uat-sequencer.ten.xyz"
  
# Sepolia Environment Values  
enclave:
  nodeSelector:
    kubernetes.io/hostname: "aks-sgxpool2-vmss000006"
host:
  fqdn: "sepolia-sequencer.ten.xyz"
```

## 🔒 Security Configuration

### Intel SGX Requirements
```yaml
# SGX Resource Allocation
resources:
  limits:
    sgx.intel.com/epc: 6Gi        # Enclave Page Cache
    sgx.intel.com/enclave: 10     # Enclave instances
    sgx.intel.com/provision: 10   # Provisioning capability
```

### External Secrets (Recommended)
```yaml
# Enable external secrets for production
externalSecrets:
  enabled: true
  secretStore:
    provider: azure-keyvault
    
# Configure sensitive data via external secrets
host:
  secretEnv:
    NODE_PRIVATEKEY: ""  # Populated by external secrets
```

### Network Security
```yaml
# Network policies for pod isolation
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ten-protocol-network-policy
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: ten-node
  policyTypes:
  - Ingress
  - Egress
```

## 📊 High Availability Design

### Dual Enclave Setup
```yaml
# Primary enclave on SGX node 1
enclave:
  nodeSelector:
    kubernetes.io/hostname: "aks-sgxpool2-vmss000005"

# Secondary enclave on SGX node 2  
enclave02:
  enabled: true
  nodeSelector:
    kubernetes.io/hostname: "aks-sgxpool2-vmss000006"
```

### Persistent Storage
```yaml
# EdgelessDB storage configuration
enclave:
  edb:
    storage:
      spec:
        storageClassName: "premium2-disk-sc"
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 100Gi
```

## 🛠️ Development Workflow

### Local Development
```bash
# Validate Helm charts
helm lint charts/ten-node
helm template charts/ten-node --debug

# Test in development environment
helm upgrade --install ten-node-dev ./charts/ten-node \
  --namespace dev \
  --set enclave.image.tag=dev-latest
```

### GitOps Workflow
1. **Make changes** to chart templates or values
2. **Create Pull Request** with proposed changes
3. **Review & Merge** to main branch
4. **ArgoCD automatically syncs** changes to clusters
5. **Monitor deployment** via ArgoCD UI

### Testing Strategy
```bash
# Validate chart rendering
helm template charts/ten-node --values charts/ten-node/values.yaml

# Run chart tests
helm test ten-node

# Validate Kubernetes resources
kubectl apply --dry-run=client -f rendered-manifests.yaml
```

## 🔍 Monitoring & Observability

### Health Checks
```yaml
# Enable health probes for production
enclave:
  readinessProbe:
    enabled: true
    httpGet:
      path: /health
      port: 11001
  livenessProbe:
    enabled: true
    httpGet:
      path: /health  
      port: 11001
```

### Metrics & Logging
```yaml
# Enable metrics collection
config:
  host:
    debug:
      enablemetrics: true
      metricshttpport: 9090
```

### ArgoCD Monitoring
- **Application Health**: Monitor sync status and health
- **Drift Detection**: Alerts on manual cluster changes
- **Deployment History**: Track all changes via Git history

## 🚨 Troubleshooting

### Common Issues

#### SGX Resource Allocation
```bash
# Check SGX resources
kubectl describe nodes | grep -A 10 "sgx.intel.com"

# Verify SGX device plugin
kubectl get pods -n kube-system | grep sgx-device-plugin
```

#### Enclave Startup Issues
```bash
# Check enclave logs
kubectl logs -f ten-node-enclave-0 -c enclave

# Verify SGX attestation
kubectl exec -it ten-node-enclave-0 -- dmesg | grep -i sgx
```

#### ArgoCD Sync Issues
```bash
# Check application status
argocd app get ten-uat-apps

# Force refresh
argocd app refresh ten-uat-apps

# Manual sync
argocd app sync ten-uat-apps --prune
```

### Debug Commands
```bash
# Port forward to services
kubectl port-forward svc/ten-node-host 8080:80
kubectl port-forward svc/ten-tools-tenscan-fe 3000:80

# Check service endpoints
kubectl get endpoints -n ten-protocol

# View resource utilization
kubectl top pods -n ten-protocol
```

## 📚 Documentation

- **[Ten Node Chart](charts/ten-node/README.md)**: Core blockchain node deployment
- **[Ten Tools Chart](charts/ten-tools/README.md)**: Supporting services and tools
- **[ArgoCD Pattern](ARGOCD-DEPLOYMENT-PATTERN.md)**: GitOps deployment architecture
- **[Ten Protocol Docs](https://docs.ten.org)**: Official protocol documentation

## 🤝 Contributing

### Development Process
1. **Fork** the repository
2. **Create feature branch**: `git checkout -b feature/new-feature`
3. **Make changes** and test thoroughly
4. **Submit Pull Request** with detailed description
5. **Code Review** by maintainers
6. **Merge** after approval

### Chart Development Guidelines
- Follow **Helm best practices** and conventions
- Include **comprehensive documentation**
- Add **appropriate labels and annotations**
- Test with **multiple value configurations**
- Ensure **security best practices**

### Commit Message Format
```
type(scope): description

feat(ten-node): add support for custom SGX node selection
fix(ten-tools): resolve faucet token distribution issue
docs(argocd): update deployment pattern documentation
```

## 📄 License

This project is licensed under the terms specified in the Ten Protocol main repository. See the [Ten Protocol GitHub](https://github.com/ten-protocol) for license details.

## 🆘 Support

### Community Resources
- **📖 Documentation**: [docs.ten.xyz](https://docs.ten.xyz)
- **💬 Discord**: [Ten Protocol Community](https://discord.gg/tenprotocol)  
- **🐛 Issues**: [GitHub Issues](https://github.com/ten-protocol/ten-apps/issues)
- **📧 Email**: [support@ten.org](mailto:support@ten.xyz)

### Enterprise Support
For enterprise deployments and support, contact the Ten Protocol team through official channels.

---

**Ten Protocol** - Privacy-First Layer 2 Blockchain Infrastructure
