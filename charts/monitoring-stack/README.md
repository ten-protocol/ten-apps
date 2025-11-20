# Monitoring Stack

This Helm chart deploys a complete monitoring stack for Kubernetes clusters, including:

- **kube-state-metrics**: Exposes Kubernetes object metrics (pods, deployments, etc.)
- **prometheus-node-exporter**: Exposes node-level metrics (CPU, memory, disk, network)
- **grafana-agent**: Lightweight agent that scrapes metrics and forwards to Mimir

## Installation via ArgoCD

### 1. Add chart to ten-apps repository

Copy this `monitoring-stack` directory to your `ten-apps` repository under `charts/` directory.

### 2. Create ArgoCD Application

Create an ArgoCD Application with the following configuration:

**Application Name**: `monitoring-stack-<env>`  
**Project**: `default`  
**Sync Policy**: Manual (no auto-sync)

**Source**:
- Repository URL: `https://github.com/ten-protocol/ten-apps.git`
- Path: `charts/monitoring-stack`
- Target Revision: `main` (or your branch)

**Destination**:
- Cluster: `in-cluster`
- Namespace: `monitoring`

**Helm Parameters** (Set in ArgoCD UI):
```yaml
mimir.url: "https://mimir.ten.xyz"
mimir.auth.username: "ten"
mimir.auth.password: "your-password-here"
```

### 3. Sync from ArgoCD UI

Once created, manually sync the application from the ArgoCD UI.

## Configuration

### Mimir Credentials

Set these parameters in the ArgoCD UI under "Parameters":

| Parameter | Description | Example |
|-----------|-------------|---------|
| `mimir.url` | Mimir endpoint URL (without /api/v1/push) | `https://mimir.ten.xyz` |
| `mimir.auth.username` | Basic auth username | `ten` |
| `mimir.auth.password` | Basic auth password | `secret` |

### Component Configuration

You can disable individual components by setting:

```yaml
kube-state-metrics.enabled: false
node-exporter.enabled: false
grafana-agent.enabled: false
```

## Verifying Installation

Check that all pods are running:

```bash
kubectl get pods -n monitoring
```

Expected pods:
- `kube-state-metrics-*`
- `node-exporter-*` (one per node, DaemonSet)
- `grafana-agent-*` (one per node, DaemonSet)

Check Grafana Agent logs to verify metrics are being sent:

```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana-agent -c grafana-agent --tail=50
```

You should see no error messages related to Mimir connectivity.

## Metrics Collected

- **Container metrics**: CPU, memory, network I/O per container
- **Pod metrics**: Status, restarts, resource requests/limits
- **Node metrics**: CPU, memory, disk, network per node  
- **Kubernetes state**: Deployment status, pod counts, etc.

All metrics are forwarded to the configured Mimir endpoint in real-time.

## Multi-Environment Support

Deploy to different environments by creating separate ArgoCD Applications:

- `monitoring-stack-dev`
- `monitoring-stack-staging`
- `monitoring-stack-prod`

Each can point to different clusters and use environment-specific Mimir credentials.
