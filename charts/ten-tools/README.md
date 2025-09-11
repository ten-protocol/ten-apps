# Ten Tools Helm Chart

## Overview

The `ten-tools` Helm chart deploys the supporting tools and user-facing applications for the Ten Protocol ecosystem. This includes block explorers, faucets, and bridge interfaces that provide essential services for developers and users interacting with the Ten Protocol network.

## Architecture Components

### 🔍 TenScan (Block Explorer)
- **API Backend**: Blockchain data indexing and API services
- **Frontend**: Web interface for exploring blocks, transactions, and contracts
- **Purpose**: Provides transparency and visibility into the Ten Protocol blockchain

### 💧 Faucet
- **Purpose**: Distributes test tokens for development and testing
- **Features**: JWT-based authentication, rate limiting, configurable amounts
- **Integration**: Connects directly to Ten Protocol L2 validator nodes

### 🌉 Bridge Frontend  
- **Purpose**: User interface for cross-chain asset transfers
- **Integration**: Connects to Ten Protocol bridge contracts
- **Features**: Asset bridging between L1 (Ethereum) and L2 (Ten Protocol)

## Prerequisites

### Dependencies
- **Ten Protocol L2 Node**: Running `ten-node` chart deployment
- **Kubernetes Cluster**: Version 1.19+
- **Ingress Controller**: For external access to web interfaces

### External Services
- **L1 RPC Endpoint**: Ethereum mainnet or testnet access
- **Domain Names**: For hosting public-facing services

## Installation

### Quick Start
```bash
# Install from local chart
helm install ten-tools ./charts/ten-tools \
  --namespace ten-tools \
  --create-namespace \
  -f values-production.yaml
```

### With Custom Configuration
```bash
helm install ten-tools ./charts/ten-tools \
  --namespace ten-tools \
  --create-namespace \
  --set faucet.host="faucet.mydomain.com" \
  --set tenscan.fe.host="explorer.mydomain.com" \
  --set bridge.frontend.host="bridge.mydomain.com"
```

## Configuration

### Faucet Configuration
```yaml
faucet:
  replicaCount: 1
  image:
    repository: testnetobscuronet.azurecr.io/obscuronet/faucet_uat_testnet
    tag: latest
  
  # Network configuration
  nodeHost: "l2-validator"  # Ten Protocol L2 node service
  nodePort: "80"
  chainID: 443  # Ten Protocol chain ID
  
  # Faucet settings
  defaultAmount: 0.25  # Default tokens per request
  host: "faucet.tenscan.io"
  
  # Security (use external secrets in production)
  pk: "YOUR_FAUCET_PRIVATE_KEY"
  jwtSecret: "YOUR_JWT_SECRET"
```

### TenScan Configuration
```yaml
tenscan:
  api:
    replicaCount: 1
    nodeHostAddress: "l2-validator"  # Ten Protocol L2 node
    host: "api.tenscan.io"
  
  fe:
    replicaCount: 1
    env:
      apiHost: "https://api.tenscan.io"
      version: "v1.0.0"
      environment: "uat"
    host: "tenscan.io"
```

### Bridge Frontend Configuration
```yaml
bridge:
  frontend:
    enabled: false  # Enable for bridge deployment
    replicaCount: 1
    host: "uat-bridge.ten.xyz"
    env:
      apiHost: "https://rpc.uat-gw-testnet.ten.xyz/v1"
    
    resources:
      limits:
        cpu: "2"
        memory: 2Gi
      requests:
        cpu: "1"
        memory: 1Gi
```

## Service Exposure

### Ingress Configuration

#### TenScan Explorer
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tenscan-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - tenscan.io
    secretName: tenscan-tls
  rules:
  - host: tenscan.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ten-tools-tenscan-fe
            port:
              number: 80
```

#### Faucet Service
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: faucet-ingress
spec:
  tls:
  - hosts:
    - faucet.tenscan.io
    secretName: faucet-tls
  rules:
  - host: faucet.tenscan.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ten-tools-faucet
            port:
              number: 80
```

## Security Configuration

### External Secrets (Recommended)
```yaml
# Deploy external secret for faucet private key
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: ten-tools-secrets
spec:
  provider:
    azurekv:  # or aws/gcp
      vaultUrl: "https://your-keyvault.vault.azure.net/"

---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: faucet-secrets
spec:
  secretStoreRef:
    name: ten-tools-secrets
    kind: SecretStore
  target:
    name: faucet-private-key
  data:
  - secretKey: private-key
    remoteRef:
      key: faucet-private-key
  - secretKey: jwt-secret
    remoteRef:
      key: faucet-jwt-secret
```

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ten-tools-network-policy
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: ten-tools
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: ten-protocol
    ports:
    - protocol: TCP
      port: 80
```

## Monitoring and Logging

### Health Checks
```yaml
faucet:
  readinessProbe:
    httpGet:
      path: /health
      port: 80
  livenessProbe:
    httpGet:
      path: /health
      port: 80

tenscan:
  api:
    readinessProbe:
      httpGet:
        path: /api/health
        port: 80
```

### Prometheus Monitoring
```yaml
# ServiceMonitor for Prometheus scraping
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ten-tools-metrics
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: ten-tools
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

## Environment-Specific Configurations

### Development Environment
```yaml
# values-dev.yaml
faucet:
  defaultAmount: 1.0  # Higher amounts for testing
  chainID: 443
  nodeHost: "ten-node-host.ten-dev"

tenscan:
  fe:
    env:
      environment: "development"
      apiHost: "https://api-dev.tenscan.io"
```

### UAT Environment
```yaml
# values-uat.yaml
faucet:
  defaultAmount: 0.5
  host: "uat-faucet.ten.xyz"

tenscan:
  fe:
    env:
      environment: "uat"
      apiHost: "https://uat-api.tenscan.io"
    host: "uat-tenscan.io"
```

### Production Environment
```yaml
# values-production.yaml
faucet:
  defaultAmount: 0.1  # Conservative amounts
  replicaCount: 2     # High availability
  
tenscan:
  api:
    replicaCount: 3   # Scale for production load
  fe:
    replicaCount: 2
    env:
      environment: "production"

bridge:
  frontend:
    enabled: true
    replicaCount: 2
```

## Troubleshooting

### Common Issues

#### Faucet Not Distributing Tokens
```bash
# Check faucet logs
kubectl logs -f deployment/ten-tools-faucet

# Verify L2 node connectivity
kubectl exec -it deployment/ten-tools-faucet -- \
  curl http://l2-validator:80/eth_blockNumber

# Check private key configuration
kubectl get secret faucet-private-key -o yaml
```

#### TenScan Not Loading Data
```bash
# Check API connectivity to L2 node
kubectl logs -f deployment/ten-tools-tenscan-api

# Test API endpoints
kubectl port-forward svc/ten-tools-tenscan-api 8080:80
curl http://localhost:8080/api/blocks
```

#### Bridge Frontend Issues
```bash
# Check frontend configuration
kubectl get configmap ten-tools-bridge-config -o yaml

# Verify RPC endpoint connectivity
kubectl exec -it deployment/ten-tools-bridge-frontend -- \
  curl https://rpc.uat-gw-testnet.ten.xyz/v1
```

### Debug Commands
```bash
# Port forward to access services locally
kubectl port-forward svc/ten-tools-faucet 3000:80
kubectl port-forward svc/ten-tools-tenscan-fe 8080:80
kubectl port-forward svc/ten-tools-bridge-frontend 9000:80

# Check service endpoints
kubectl get endpoints ten-tools-faucet
kubectl get endpoints ten-tools-tenscan-api
```

## Values Reference

### Faucet Values
| Parameter | Description | Default |
|-----------|-------------|---------|
| `faucet.replicaCount` | Number of faucet replicas | `1` |
| `faucet.defaultAmount` | Default token amount per request | `0.25` |
| `faucet.chainID` | Ten Protocol chain ID | `443` |
| `faucet.host` | Faucet hostname | `faucet.tenscan.io` |

### TenScan Values
| Parameter | Description | Default |
|-----------|-------------|---------|
| `tenscan.api.replicaCount` | Number of API replicas | `1` |
| `tenscan.fe.replicaCount` | Number of frontend replicas | `1` |
| `tenscan.fe.env.environment` | Environment name | `uat` |

### Bridge Values
| Parameter | Description | Default |
|-----------|-------------|---------|
| `bridge.frontend.enabled` | Enable bridge frontend | `false` |
| `bridge.frontend.host` | Bridge hostname | `uat-bridge.ten.xyz` |

## Scaling and Performance

### Horizontal Pod Autoscaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: tenscan-api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ten-tools-tenscan-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Support

For issues and questions:
- **Documentation**: [Ten Protocol Docs](https://docs.ten.org)
- **GitHub Issues**: [ten-protocol/ten-apps](https://github.com/ten-protocol/ten-apps)
- **Community**: [Discord](https://discord.gg/tenprotocol)