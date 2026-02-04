# External Integrations

**Analysis Date:** 2026-02-04

## APIs & External Services

**Blockchain:**
- Ethereum - Cryptographic operations for backup/recovery
  - SDK/Client: github.com/ethereum/go-ethereum v1.16.8
  - Auth: ECIES encryption with secp256k1 keys

**Video Services:**
- Remotion - Video generation and rendering
  - SDK/Client: @remotion/cli 4.0.0
  - Auth: No authentication required

## Data Storage

**Databases:**
- PostgreSQL
  - Connection: Kubernetes-managed via Helm charts
  - Client: postgres:16-alpine image

**File Storage:**
- MinIO (S3-compatible)
  - Endpoint: lgtm-minio.monitoring.svc:9000
  - Bucket: tempo-traces
  - Auth: access_key/secret_key (grafana-mimir/supersecret)

**Caching:**
- None detected

## Authentication & Identity

**Auth Provider:**
- Custom ECIES encryption
  - Implementation: secp256k1 private key based encryption/decryption
  - Usage: Backup data protection and shared secret management

## Monitoring & Observability

**Error Tracking:**
- None detected

**Logs:**
- Tempo distributed tracing
  - Backend: S3 (MinIO)
  - Protocols: OTLP (gRPC/HTTP), Zipkin, Jaeger, OpenCensus

**Metrics:**
- Tempo metrics generator enabled
- Service monitors available but disabled

## CI/CD & Deployment

**Hosting:**
- Kubernetes via ArgoCD GitOps

**CI Pipeline:**
- ArgoCD automated sync from GitHub
  - Repository: https://github.com/ten-protocol/ten-apps.git
  - Target revision: main

## Environment Configuration

**Required env vars:**
- Kubernetes secrets for database connections
- MinIO credentials (access_key, secret_key)
- Private key paths for backup decryption

**Secrets location:**
- Kubernetes secrets (ArgoCD-managed)
- PEM files for ECIES private keys

## Webhooks & Callbacks

**Incoming:**
- None detected

**Outgoing:**
- None detected

---

*Integration audit: 2026-02-04*