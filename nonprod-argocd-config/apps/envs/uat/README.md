# UAT Environment Configuration

## Overview

The **User Acceptance Testing (UAT)** environment is a comprehensive deployment of the Ten Protocol infrastructure on Azure Kubernetes Service (AKS). It serves as a staging environment for testing protocol updates, validator configurations, and network changes before production deployment.

## 🏗️ Environment Architecture

### Network Configuration
- **Chain ID**: 7443
- **L1 Network**: Ethereum Sepolia (`chainid: 11155111`)
- **L1 RPC**: `ws://l1.sepolia.ten.xyz:8546`
- **L1 Blob Archive**: `https://ethereum-sepolia-beacon-api.publicnode.com/`

### Deployment Strategy
- **GitOps Pattern**: ArgoCD-based GitOps using app-of-apps pattern
- **Sync Policy**: Manual (controlled deployments)
- **Namespace**: `uat`
- **Container Registry**: `testnetobscuronet.azurecr.io`

---

## 📦 Component Overview

### 1. Sequencer (`uat-sequencer`)
**Role**: Genesis node responsible for block production and network coordination

**Node Allocation**:
- **Primary Enclave**: `vmss00002e` (Kubernetes node)
- **Secondary Enclave (enclave02)**: `vmss00002f`

**Configuration**:
```yaml
- Node Type: sequencer
- Genesis: true
- FQDN: uat-sequencer.ten.xyz
- P2P Address: uat-sequencer.ten.xyz:10000
```

**Resources**:
| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|------------|-----------|----------------|--------------|
| Sequencer Enclave | 2000m | 4000m | 6Gi | 8Gi |
| Sequencer Enclave02 | 2000m | 2000m | 4Gi | 6Gi |

**Access**:
- RPC HTTP: `http://uat-sequencer-ten-node-host:80`
- RPC WebSocket: `ws://uat-sequencer-ten-node-host:81`
- P2P: `uat-sequencer-ten-node-host:10000`

---

### 2. Validators (Validator-01, Validator-02, Validator-03)
**Role**: Network validators that validate blocks and maintain network state

#### Validator-01
- **Node Allocation**: `vmss00002g`
- **FQDN**: `uat-validator-01.ten.xyz`
- **Resources**: 3000m CPU request / 4000m limit, 6Gi / 8Gi memory

#### Validator-02
- **Node Allocation**: `vmss00002h`
- **FQDN**: `uat-validator-02.ten.xyz`
- **Resources**: 3000m CPU request / 4000m limit, 6Gi / 8Gi memory

#### Validator-03 (NEW)
- **Node Allocation**: `vmss00002g` (co-located with Validator-01)
- **FQDN**: `uat-validator-03.ten.xyz`
- **Resources**: 3000m CPU request / 4000m limit, 6Gi / 8Gi memory
- **Status**: Recently added to increase network redundancy

**Configuration**:
```yaml
- Node Type: validator
- Genesis: false
- P2P Address: uat-validator-XX.ten.xyz:10000
```

---

### 3. Gateway (`uat-gateway`)
**Role**: RPC gateway and frontend for user interaction

**Node Allocation**: `vmss00002h` (co-located with Validator-02)

**Configuration**:
- **Frontend Domain**: `uat-gw-testnet.ten.xyz`
- **RPC Domain**: `rpc.uat-gw-testnet.ten.xyz`
- **Database**: CosmosDB
- **TLS**: Enabled

**Resources**:
| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|------------|-----------|----------------|--------------|
| Gateway Frontend | 500m | 500m | 1Gi | 1Gi |
| Gateway Backend | 500m | 1000m | 5Gi | 5Gi |

**Access**:
- Frontend: `https://uat-gw-testnet.ten.xyz`
- RPC: `https://rpc.uat-gw-testnet.ten.xyz`

---

### 4. Tools & Supporting Services
- **TenScan**: Block explorer interface
- **Faucet**: Test token distribution
- **Bridge**: Cross-chain asset interface
- **Postgres Client**: Database utilities

---

## 🖥️ Node Resource Allocation Summary

| AKS Node | Hostname | Primary Component | Co-located | CPU Request | Total CPU Limit | Memory | Status |
|----------|----------|------------------|-----------|------------|--------------|--------|--------|
| **vmss00002e** | aks-sgxpool-23126921-vmss00002e | Sequencer (Primary) | Enclave | 2000m | 4000m | 6Gi / 8Gi | ✅ Well-utilized |
| **vmss00002f** | aks-sgxpool-23126921-vmss00002f | Sequencer (Enclave02) | - | 2000m | 2000m | 4Gi / 6Gi | ✅ Adequate |
| **vmss00002g** | aks-sgxpool-23126921-vmss00002g | Validator-01 | Validator-03 | 6000m | 8000m | 12Gi / 16Gi | ⚠️ Heavy (monitor CPU) |
| **vmss00002h** | aks-sgxpool-23126921-vmss00002h | Validator-02 | Gateway | 4000m | 5500m | 12Gi / 14Gi | ✅ Balanced |

### Resource Recommendations
- **vmss00002g**: Ensure node has ≥16 CPU cores and 32GB RAM (hosts 2 validators)
- **vmss00002h**: Ensure node has ≥8 CPU cores and 16GB RAM (validator + gateway)
- Monitor CPU contention on vmss00002g during peak load

---

## 🔐 External Secrets Configuration

All sensitive data is managed via external secrets. Required secrets:

### Sequencer Secrets
```
UAT-SEQUENCER-NODE-PRIVATEKEY         # Node private key
seq-db-connstring                      # PostgreSQL connection string
```

### Validator Secrets
```
UAT-VALIDATOR-01-NODE-PRIVATEKEY      # Validator-01 private key
val-01-db-connstring                   # Validator-01 DB connection

UAT-VALIDATOR-02-NODE-PRIVATEKEY      # Validator-02 private key
val-02-db-connstring                   # Validator-02 DB connection

UAT-VALIDATOR-03-NODE-PRIVATEKEY      # Validator-03 private key (NEW)
val-03-db-connstring                   # Validator-03 DB connection (NEW)
```

### Gateway Secrets
```
uattestnet-gateway-connection-string   # Gateway CosmosDB connection
```

### Common Secrets
```
DRPC-SEPOLIA-API-KEY                  # DRPC API for Sepolia L1
DRPC-SEPOLIA-BEACON-URL               # DRPC Beacon API URL
```

---

## 📋 ArgoCD Application Structure

### Root Application
**File**: `uat-apps.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ten-uat-apps
spec:
  source:
    path: nonprod-argocd-config/apps/envs/uat
    directory:
      recurse: true
  destination:
    namespace: argocd
  syncPolicy:
    automated: {}
```

### Individual Applications
Each component has its own ArgoCD application:

- `sequencer-app.yaml` - Sequencer deployment
- `validator-01-app.yaml` - Validator-01 deployment
- `validator-02-app.yaml` - Validator-02 deployment
- `validator-03-app.yaml` - Validator-03 deployment (NEW)
- `gateway-app.yaml` - Gateway deployment
- `tools-app.yaml` - Supporting tools

---

## 🚀 Deployment & Management

### Prerequisites
- Azure AKS cluster with SGX-capable nodes
- ArgoCD installed in `argocd` namespace
- Kubernetes 1.24+
- External Secrets Operator (ESO) configured
- Azure Key Vault integration

### Initial Deployment
```bash
# 1. Ensure secrets are created in Azure Key Vault
az keyvault secret set --vault-name <vault-name> \
  --name "UAT-SEQUENCER-NODE-PRIVATEKEY" \
  --value "<private-key>"

# 2. Apply UAT apps to ArgoCD
kubectl apply -f nonprod-argocd-config/apps/uat-apps.yaml

# 3. Monitor deployment
argocd app list | grep uat
argocd app sync ten-uat-apps
```

### Update Component Configuration
```bash
# 1. Edit values file
vi nonprod-argocd-config/apps/envs/uat/valuesFile/values-uat-validator-01.yaml

# 2. Commit changes
git add .
git commit -m "update: adjust validator-01 resources"

# 3. ArgoCD automatically syncs (or manually sync)
argocd app sync uat-validator-01
```

### Adding New Validators
1. Create new values file: `values-uat-validator-XX.yaml`
2. Create application file: `validator-XX-app.yaml`
3. Update node selector to available SGX node
4. Configure external secrets in Key Vault
5. Commit and push to main branch
6. ArgoCD automatically detects and deploys

---

## 🔍 Monitoring & Health Checks

### Check Application Status
```bash
# List all UAT applications
argocd app list | grep uat

# Get detailed status
argocd app get uat-validator-01

# Monitor health
kubectl get all -n uat
```

### View Component Logs
```bash
# Sequencer logs
kubectl logs -f deployment/uat-sequencer -n uat -c host

# Validator logs
kubectl logs -f deployment/uat-validator-01 -n uat -c host

# Enclave logs
kubectl logs -f deployment/uat-validator-01 -n uat -c enclave

# Gateway logs
kubectl logs -f deployment/uat-gateway -n uat
```

### Monitor Resource Usage
```bash
# View pod resource consumption
kubectl top pods -n uat

# Describe node resources
kubectl describe node aks-sgxpool-23126921-vmss00002g

# Check SGX resources
kubectl describe nodes | grep -A 10 "sgx.intel.com"
```

### Health Endpoints
- **Sequencer**: `http://uat-sequencer-ten-node-host:9090/metrics`
- **Validators**: `http://uat-validator-XX-ten-node-host:9090/metrics`
- **Gateway**: Health check via `/health` endpoint

---

## 🧪 Testing & Validation

### Network Connectivity
```bash
# Test sequencer RPC
curl -s http://uat-sequencer-ten-node-host:80 | jq .

# Test validator RPC
curl -s http://uat-validator-01-ten-node-host:80 | jq .

# Test gateway
curl -s https://rpc.uat-gw-testnet.ten.xyz | jq .
```

### Validator Sync Status
```bash
# Connect to validator pod
kubectl exec -it pod/uat-validator-01-0 -n uat -- /bin/bash

# Check block synchronization
curl http://localhost:80 -X POST -d '{"jsonrpc":"2.0","method":"eth_blockNumber"}'
```

### Gateway Functionality
```bash
# Test frontend access
curl -s https://uat-gw-testnet.ten.xyz

# Test RPC endpoint
curl -X POST https://rpc.uat-gw-testnet.ten.xyz \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","id":1}'
```

---

## 🐛 Troubleshooting

### Validator Not Syncing
```bash
# 1. Check pod status
kubectl get pods -n uat -l app=validator-01

# 2. Check logs for errors
kubectl logs -f pod/uat-validator-01-0 -n uat -c host

# 3. Verify P2P connectivity
kubectl exec pod/uat-validator-01-0 -n uat -- netstat -tuln | grep 10000

# 4. Verify network configuration
kubectl get configmap -n uat uat-validator-01-config -o yaml
```

### SGX Resource Issues
```bash
# Check SGX EPC allocation
kubectl describe nodes aks-sgxpool-23126921-vmss00002g | grep -A 5 "sgx.intel.com"

# Check if pods can allocate SGX resources
kubectl describe pod uat-validator-01-0 -n uat | grep -A 10 "Requests"
```

### ArgoCD Sync Failures
```bash
# Check application status
argocd app get uat-validator-01

# Get detailed error
argocd app get uat-validator-01 --refresh

# Manual sync with verbose output
argocd app sync uat-validator-01 --verbose

# Check for resource conflicts
kubectl get all -n uat -o yaml | grep -i error
```

### Database Connection Issues
```bash
# Test PostgreSQL connectivity from pod
kubectl exec pod/uat-validator-01-0 -n uat -- \
  psql -h <db-host> -U <db-user> -d <db-name> -c "SELECT version();"

# Check secret is mounted correctly
kubectl get secret -n uat | grep validator-01
kubectl exec pod/uat-validator-01-0 -n uat -- env | grep POSTGRES
```

---

## 🔄 Maintenance & Updates

### Update Image Version
```yaml
# Update in values file
enclave:
  image:
    tag: "v1.8.0"  # Update version

# Commit and push
git add nonprod-argocd-config/apps/envs/uat/valuesFile/
git commit -m "update: bump validator image to v1.8.0"
git push origin main
```

### Scaling Resources
```yaml
# Increase CPU/Memory limits
enclave:
  edb:
    resources:
      requests:
        cpu: 4000m      # Increase from 3000m
        memory: 8Gi     # Increase from 6Gi
```

### Rolling Updates
- ArgoCD performs rolling updates automatically
- Monitor deployment with: `kubectl rollout status -n uat`
- Rollback if needed: `kubectl rollout undo -n uat`

---

## 📊 Performance Metrics

### Expected Performance
- **Block Time**: ~1-2 seconds (configured as 1s)
- **Batch Size**: 56,320 bytes
- **Rollup Interval**: 6 hours
- **Validator Consensus**: BFT consensus

### Monitoring Dashboard
Key metrics to monitor:
- **Block Height**: Current sync status
- **Pending Transactions**: Queue depth
- **Gas Used**: Transaction processing load
- **CPU/Memory**: Node resource utilization
- **Network Latency**: P2P connectivity quality

---

## 📝 File Structure Reference

```
nonprod-argocd-config/apps/envs/uat/
├── README.md                                    # This file
├── sequencer-app.yaml                          # Sequencer ArgoCD app
├── validator-01-app.yaml                       # Validator-01 ArgoCD app
├── validator-02-app.yaml                       # Validator-02 ArgoCD app
├── validator-03-app.yaml                       # Validator-03 ArgoCD app (NEW)
├── gateway-app.yaml                            # Gateway ArgoCD app
├── tools-app.yaml                              # Tools ArgoCD app
├── l1-values.yaml                              # L1 configuration (shared)
└── valuesFile/
    ├── values-uat-sequencer.yaml               # Sequencer values
    ├── values-uat-validator-01.yaml            # Validator-01 values
    ├── values-uat-validator-02.yaml            # Validator-02 values
    ├── values-uat-validator-03.yaml            # Validator-03 values (NEW)
    ├── values-uat-gateway.yaml                 # Gateway values
    ├── values-uat-tools.yaml                   # Tools values
    ├── values-uat-postgres-client.yaml         # Postgres client values
    └── l1-values.yaml                          # L1 network configuration
```

---

## 🔗 Related Documentation

- **[Parent README](../../../README.md)**: Main repository documentation
- **[ArgoCD Pattern](../../../ARGOCD-DEPLOYMENT-PATTERN.md)**: GitOps architecture details
- **[Ten Node Chart](../../../charts/ten-node/README.md)**: Helm chart documentation
- **[Ten Tools Chart](../../../charts/ten-tools/README.md)**: Tools chart documentation
- **[Ten Protocol Docs](https://docs.ten.xyz)**: Official protocol documentation

---

## 🆘 Support & Escalation

### Common Issues Contacts
- **Infrastructure**: DevOps team via #ops-support Slack channel
- **Protocol**: Protocol team via #protocol-dev Slack channel
- **Network**: Network team via #network-ops Slack channel

### Logging a Issue
1. Document the problem with timestamps
2. Collect relevant logs: `kubectl logs -f pod-name -n uat`
3. Check ArgoCD status: `argocd app get app-name`
4. Report in #incidents Slack channel with details

---

## 📅 Deployment History & Changelog

### Recent Updates
- **2025-10-31**: Added Validator-03 to increase network redundancy
- **2025-10-28**: Moved Gateway from vmss00002g to vmss00002h for load balancing
- **2025-10-01**: Deployed UAT environment v1.7.0

### Version Information
- **Current Enclave Version**: v1.7.0
- **Current Host Version**: v1.7.0
- **Current Gateway Version**: e454320

---

**Last Updated**: October 31, 2025
**Environment**: UAT
**Maintained By**: Infrastructure Team
