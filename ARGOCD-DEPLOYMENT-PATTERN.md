# ArgoCD Deployment Design Pattern

## Overview

This repository implements a **GitOps deployment pattern** using ArgoCD with a sophisticated **App-of-Apps architecture**. The design enables multi-environment management of Ten Protocol infrastructure with automated synchronization and progressive deployment strategies.

## Architecture Pattern: App-of-Apps

### 🏗️ Hierarchical Structure

```
Root App (Commented Out)
├── Environment Apps (uat-apps, sepolia-apps, dev-apps)
    ├── Component Apps (validator-02, sequencer, tools, gateway)
        └── Helm Charts (ten-node, ten-tools, ten-gateway)
```

### 📁 Directory Structure
```
nonprod-argocd-config/
├── apps/
│   ├── root-app.yaml          # (Commented) Root app-of-apps
│   ├── uat-apps.yaml          # UAT environment app-of-apps  
│   ├── sepolia-apps.yaml      # Sepolia testnet apps
│   ├── dev-apps.yaml          # Development apps
│   └── envs/
│       ├── uat/
│       │   ├── validator-02-app.yaml    # Individual component apps
│       │   ├── sequencer-app.yaml
│       │   ├── tools-app.yaml
│       │   └── valuesFile/
│       │       ├── values-uat-validator-02.yaml  # Environment-specific values
│       │       ├── values-uat-sequencer.yaml
│       │       ├── values-uat-tools.yaml
│       │       └── l1-values.yaml               # Shared L1 configuration
│       ├── sepolia/
│       └── dev/
```

## Deployment Flow

### 1. **Bootstrap Process**
```yaml
# Root App (Currently Commented)
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ten-nonprod-root-app
  annotations:
    argocd.argoproj.io/sync-wave: "0"  # Deploys first
spec:
  source:
    path: nonprod-argocd-config/apps
    directory:
      recurse: false  # Only top-level apps
```

### 2. **Environment-Level Apps**
```yaml
# UAT Environment App
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ten-uat-apps
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Deploys after root
spec:
  source:
    path: nonprod-argocd-config/apps/envs/uat
    directory:
      recurse: true  # Discovers all component apps
  syncPolicy:
    automated:
      prune: true
      selfHeal: false  # Manual healing for production safety
```

### 3. **Component-Level Apps**
```yaml
# Individual Ten Node Validator
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: uat-validator-02
spec:
  source:
    path: charts/ten-node  # Points to actual Helm chart
    helm:
      valueFiles:
        - ../../nonprod-argocd-config/apps/envs/uat/valuesFile/values-uat-validator-02.yaml
        - ../../nonprod-argocd-config/apps/envs/uat/valuesFile/l1-values.yaml
  destination:
    namespace: uat
```

## Key Design Principles

### 🎯 **Separation of Concerns**
- **Charts**: Reusable Helm templates in `charts/`
- **Configuration**: Environment-specific values in `nonprod-argocd-config/`
- **Apps**: ArgoCD application definitions for deployment orchestration

### 🔄 **Progressive Deployment**
```yaml
# Sync waves ensure proper deployment order
argocd.argoproj.io/sync-wave: "0"  # Root apps first
argocd.argoproj.io/sync-wave: "1"  # Environment apps second  
argocd.argoproj.io/sync-wave: "2"  # Infrastructure components
argocd.argoproj.io/sync-wave: "3"  # Applications
```

### 🌍 **Multi-Environment Strategy**

#### Environment Isolation
- **Namespace Separation**: `uat`, `sepolia`, `dev`
- **Value Override**: Environment-specific configuration files
- **Resource Isolation**: Separate ArgoCD projects per environment

#### Configuration Inheritance
```yaml
# Shared L1 Configuration
# l1-values.yaml
config:
  network:
    l1:
      chainid: 11155111  # Sepolia
      websocketurl: "wss://sepolia.infura.io/ws/v3/KEY"

# Component-Specific Overrides  
# values-uat-validator-02.yaml
enclave:
  nodeSelector:
    kubernetes.io/hostname: "aks-sgxpool2-vmss000006"
host:
  fqdn: "uat-validator-02.ten.xyz"
```

## Deployment Patterns

### 🚀 **Blue-Green Deployment**
```yaml
# Blue Environment (Current)
metadata:
  name: uat-validator-01
spec:
  destination:
    namespace: uat-blue

# Green Environment (New Version)
metadata:
  name: uat-validator-01-green  
spec:
  destination:
    namespace: uat-green
```

### 🎲 **Canary Deployment**
```yaml
# Primary Validator (Stable)
enclave:
  replicaCount: 1
  image:
    tag: "v1.5.1"

# Canary Validator (New Version)  
enclave02:
  enabled: true
  image:
    tag: "v1.6.0-beta"
```

### 📦 **Multi-Chart Application**
```yaml
# Tools Deployment (Multiple Services)
source:
  path: charts/ten-tools
  helm:
    valueFiles:
      - ../../nonprod-argocd-config/apps/envs/uat/valuesFile/values-uat-tools.yaml
# Deploys: TenScan + Faucet + Bridge in single chart
```

## Sync Strategies

### 🤖 **Automated Sync (Development)**
```yaml
syncPolicy:
  automated:
    prune: true      # Remove orphaned resources
    selfHeal: true   # Auto-fix drift
    allowEmpty: false
  syncOptions:
    - CreateNamespace=true
```

### 👥 **Manual Sync (Production)**
```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: false  # Manual intervention required
  syncOptions:
    - CreateNamespace=true
    - PruneLast=true  # Delete resources after new ones are healthy
```

## Security & Compliance

### 🔐 **GitOps Security Model**
- **Declarative Configuration**: All changes via Git commits
- **RBAC Integration**: ArgoCD respects Kubernetes RBAC
- **Audit Trail**: Git history provides complete change log
- **Drift Detection**: Alerts on manual cluster changes

### 🛡️ **Secret Management**
```yaml
# External Secrets Integration
externalSecrets:
  enabled: true
  secretStore:
    provider: azure-keyvault

# ArgoCD ignores secret values
spec:
  ignoreDifferences:
  - group: ""
    kind: Secret
    jsonPointers:
    - /data
```

## Monitoring & Observability

### 📊 **ArgoCD Application Health**
```yaml
# Health checks for custom resources
spec:
  source:
    helm:
      parameters:
      - name: healthChecks.enabled
        value: "true"
```

### 🚨 **Deployment Notifications**
```yaml
# Slack/Email notifications on sync failures
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
data:
  service.slack: |
    token: $slack-token
  template.app-sync-failed: |
    message: Application {{.app.metadata.name}} sync failed
```

## Best Practices Implementation

### ✅ **Configuration Management**
1. **Shared Values**: Common L1 configuration in `l1-values.yaml`
2. **Environment Specific**: Node hostnames, resource limits per environment
3. **Security Separation**: Secrets via External Secrets Operator
4. **Version Control**: All configuration changes via Git PRs

### ✅ **Deployment Safety**
1. **Sync Waves**: Ordered deployment of dependencies
2. **Health Checks**: Application readiness before marking sync complete
3. **Rollback Capability**: Git revert enables quick rollbacks
4. **Pre-Sync Hooks**: Database migrations, cleanup jobs

### ✅ **Operational Excellence**
1. **Namespace Isolation**: Environment separation
2. **Resource Quotas**: Prevent resource exhaustion
3. **Network Policies**: Secure inter-pod communication
4. **Monitoring Integration**: Prometheus metrics for all components

## Troubleshooting Common Issues

### 🔧 **App-of-Apps Not Syncing**
```bash
# Check parent app status
kubectl get applications -n argocd ten-uat-apps

# Force refresh discovery
argocd app refresh ten-uat-apps

# Check for resource conflicts
kubectl get applications -n argocd -o yaml | grep -A 5 -B 5 "OutOfSync"
```

### 🔧 **Values File Not Found**
```bash
# Verify relative path from chart directory
ls -la charts/ten-node/../../nonprod-argocd-config/apps/envs/uat/valuesFile/

# Check ArgoCD can access the repo
argocd repo list
```

### 🔧 **Sync Wave Issues**
```bash
# Check sync wave order
kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,WAVE:.metadata.annotations."argocd\.argoproj\.io/sync-wave"

# Manual sync with specific wave
argocd app sync ten-uat-apps --prune --strategy=hook
```

## Migration Strategy

### From Manual Deployments to GitOps
1. **Phase 1**: Create ArgoCD applications for existing workloads
2. **Phase 2**: Implement app-of-apps pattern for environment management  
3. **Phase 3**: Enable automated sync for non-production environments
4. **Phase 4**: Add external secrets integration
5. **Phase 5**: Implement comprehensive monitoring and alerting

This ArgoCD deployment pattern provides a robust, scalable foundation for managing complex Ten Protocol infrastructure across multiple environments while maintaining security, compliance, and operational excellence.