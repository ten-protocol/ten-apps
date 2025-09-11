# Ten Node Helm Chart

## Overview

The `ten-node` Helm chart deploys the core infrastructure components for a Ten Protocol (formerly Obscuro) blockchain node. This chart manages the deployment of TEE (Trusted Execution Environment) enclaves running in Intel SGX hardware and the host components that interface with Layer 1 blockchain networks.

## Architecture Components

### 🔐 Enclave (TEE Component)
- **Purpose**: Secure computation environment using Intel SGX
- **Database**: EdgelessDB for confidential data storage
- **Deployment**: StatefulSet with persistent storage
- **Resources**: Requires SGX-capable Kubernetes nodes

### 🌐 Host (L2 Node Component)  
- **Purpose**: Layer 2 blockchain node with P2P networking
- **Interfaces**: HTTP/WebSocket RPC endpoints
- **L1 Integration**: Connects to Ethereum Sepolia testnet
- **Deployment**: Standard Kubernetes Deployment

### 💾 EdgelessDB
- **Purpose**: Confidential database running in SGX enclave
- **Storage**: 100Gi persistent volumes
- **Resources**: High memory/CPU allocation for database operations

## Prerequisites

### Hardware Requirements
- **SGX-capable Kubernetes nodes** with:
  - `sgx.intel.com/epc` resources (6Gi minimum)
  - `sgx.intel.com/enclave` slots (10 minimum)
  - `sgx.intel.com/provision` capability

### Kubernetes Setup
```bash
# Label your SGX nodes
kubectl label nodes <node-name> sgx-capable=true

# Optional: Taint nodes for dedicated SGX workloads
kubectl taint nodes <node-name> sgx=dedicated:NoSchedule
```

## Installation

### Basic Installation
```bash
# Add the chart repository (if hosted)
helm repo add ten-protocol <repository-url>
helm repo update

# Install the chart
helm install ten-node ten-protocol/ten-node \
  --namespace ten-protocol \
  --create-namespace \
  -f values-production.yaml
```

### Development Installation
```bash
# Install from local chart directory
helm install ten-node ./charts/ten-node \
  --namespace ten-dev \
  --create-namespace
```

## Configuration

### Critical Configuration Values

#### SGX Node Assignment
```yaml
enclave:
  nodeSelector:
    kubernetes.io/hostname: "your-sgx-node-hostname"
  tolerations:
  - key: sgx
    operator: Equal
    value: dedicated
    effect: NoSchedule
```

#### Network Configuration
```yaml
config:
  network:
    chainid: 443  # Ten Protocol chain ID
    l1:
      chainid: 11155111  # Sepolia testnet
      websocketurl: "wss://sepolia.infura.io/ws/v3/YOUR_KEY"
```

#### Security Configuration
```yaml
# Enable external secrets (RECOMMENDED)
externalSecrets:
  enabled: true

# Configure private keys via external secrets
host:
  secretEnv:
    NODE_PRIVATEKEY: ""  # Set via external secrets
```

### Resource Configuration

#### Enclave Resources
```yaml
enclave:
  resources:
    limits:
      memory: 4Gi
      cpu: 2000m
      sgx.intel.com/epc: 6Gi
      sgx.intel.com/enclave: 10
    requests:
      memory: 4Gi
      cpu: 1000m
```

#### EdgelessDB Resources
```yaml
enclave:
  edb:
    resources:
      limits:
        memory: 8Gi
        cpu: 4000m
        sgx.intel.com/epc: 6Gi
```

## High Availability Setup

### Dual Enclave Configuration
For production HA, enable the secondary enclave:

```yaml
enclave02:
  enabled: true
  nodeSelector:
    kubernetes.io/hostname: "your-second-sgx-node"
  # Configure with different node assignment
```

### Storage Configuration
```yaml
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

## Monitoring and Observability

### Health Checks
```yaml
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

### Metrics Configuration
```yaml
config:
  host:
    debug:
      enablemetrics: true
      metricshttpport: 9090
```

## Security Best Practices

### 1. External Secrets Integration
```yaml
externalSecrets:
  enabled: true
  secretStore:
    provider: azure-keyvault  # or aws-secretsmanager
```

### 2. Network Policies
```yaml
# Apply network policies to restrict pod communication
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ten-node-network-policy
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: ten-node
  policyTypes:
  - Ingress
  - Egress
```

### 3. Pod Security Standards
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
```

## Troubleshooting

### Common Issues

#### SGX Resource Allocation
```bash
# Check SGX resources on nodes
kubectl describe nodes | grep -A 10 "sgx.intel.com"

# Verify SGX device plugin
kubectl get pods -n kube-system | grep sgx
```

#### Enclave Startup Issues
```bash
# Check enclave logs
kubectl logs -f ten-node-enclave-0 -c enclave

# Check SGX attestation
kubectl exec -it ten-node-enclave-0 -- dmesg | grep -i sgx
```

#### Storage Issues
```bash
# Check PVC status
kubectl get pvc -n ten-protocol

# Check storage class
kubectl get storageclass
```

### Debug Commands
```bash
# Port forward to access enclave RPC
kubectl port-forward ten-node-enclave-0 11001:11001

# Port forward to access host RPC
kubectl port-forward service/ten-node-host 8080:80

# Check EdgelessDB status
kubectl exec -it ten-node-enclave-0 -c edb -- curl localhost:8080/status
```

## Values Reference

### Global Values
| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imagePullPolicy` | Image pull policy | `Always` |
| `global.destructiveDeployment` | Enable destructive operations | `true` |

### Enclave Values
| Parameter | Description | Default |
|-----------|-------------|---------|
| `enclave.replicaCount` | Number of enclave replicas | `1` |
| `enclave.image.repository` | Enclave container image | `testnetobscuronet.azurecr.io/obscuronet/sepolia_enclave` |
| `enclave.nodeSelector` | Node selector for SGX nodes | `{}` |

### Host Values
| Parameter | Description | Default |
|-----------|-------------|---------|
| `host.enabled` | Enable host deployment | `true` |
| `host.replicaCount` | Number of host replicas | `1` |
| `host.fqdn` | Host FQDN for external access | `dev-testnet-sequencer.ten.xyz` |

## Support

For issues and questions:
- **Documentation**: [Ten Protocol Docs](https://docs.ten.org)
- **GitHub Issues**: [ten-protocol/ten-apps](https://github.com/ten-protocol/ten-apps)
- **Community**: [Discord](https://discord.gg/tenprotocol)

## License

This project is licensed under the terms specified in the main Ten Protocol repository.