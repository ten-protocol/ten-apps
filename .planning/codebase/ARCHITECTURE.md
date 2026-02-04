# Architecture

**Analysis Date:** 2026-02-04

## Pattern Overview

**Overall:** GitOps Infrastructure Management with App-of-Apps Pattern

**Key Characteristics:**
- Helm-based Kubernetes application packaging
- ArgoCD GitOps continuous deployment with hierarchical app management
- Multi-environment infrastructure with environment-specific configurations
- SGX-based trusted execution environment for privacy-focused blockchain nodes

## Layers

**Infrastructure Layer:**
- Purpose: Kubernetes cluster management and SGX hardware abstraction
- Location: `charts/*/templates/`
- Contains: StatefulSets, Deployments, Services, PersistentVolumeClaims
- Depends on: Kubernetes cluster with Intel SGX support
- Used by: Application layer components

**Application Layer:**
- Purpose: Ten Protocol blockchain node components (Enclave, Host, Tools)
- Location: `charts/ten-node/`, `charts/ten-tools/`, `charts/ten-gateway/`
- Contains: Core blockchain services and supporting applications
- Depends on: Infrastructure layer, container images from Azure Container Registry
- Used by: External clients via ingress and load balancers

**Configuration Layer:**
- Purpose: Environment-specific deployment configurations
- Location: `nonprod-argocd-config/apps/envs/`, `prod-argocd-config/apps/envs/`
- Contains: Values files, ArgoCD application definitions
- Depends on: Helm charts in application layer
- Used by: ArgoCD for automated deployments

**GitOps Layer:**
- Purpose: Automated deployment orchestration and synchronization
- Location: `nonprod-argocd-config/apps/`, `prod-argocd-config/apps/`
- Contains: ArgoCD Application CRDs implementing app-of-apps pattern
- Depends on: Git repository state and target Kubernetes clusters
- Used by: ArgoCD controllers for deployment automation

## Data Flow

**Deployment Flow:**

1. Code changes committed to Git repository
2. ArgoCD detects changes via Git polling/webhooks
3. Environment-specific app-of-apps trigger individual component deployments
4. Helm charts rendered with environment-specific values
5. Kubernetes resources created/updated in target namespaces
6. StatefulSets ensure persistent data for Enclave components
7. Services expose endpoints for internal and external communication

**State Management:**
- Persistent volumes for EdgelessDB and Enclave state storage
- External secrets integration for sensitive configuration
- StatefulSets ensure stable network identities for core components

## Key Abstractions

**Enclave Abstraction:**
- Purpose: Represents TEE (Trusted Execution Environment) with Intel SGX
- Examples: `charts/ten-node/templates/enclave-statefulset.yaml`, `charts/ten-node/templates/enclave-statefulset-02.yaml`
- Pattern: StatefulSet with SGX resource allocation and persistent storage

**Host Abstraction:**
- Purpose: Represents L2 blockchain node with P2P networking
- Examples: `charts/ten-node/templates/host-deployment.yaml`
- Pattern: Deployment with external connectivity and load balancing

**Environment Configuration:**
- Purpose: Abstracts environment-specific deployment parameters
- Examples: `nonprod-argocd-config/apps/envs/uat/valuesFile/`, `prod-argocd-config/apps/envs/mainnet/valuesFile/`
- Pattern: Hierarchical values files with base configurations and overrides

**App-of-Apps Pattern:**
- Purpose: Hierarchical application management for complex deployments
- Examples: `nonprod-argocd-config/apps/uat-apps.yaml`, `nonprod-argocd-config/apps/envs/uat/sequencer-app.yaml`
- Pattern: Parent ArgoCD Application managing child Applications

## Entry Points

**Environment Bootstrap:**
- Location: `nonprod-argocd-config/apps/uat-apps.yaml`, `prod-argocd-config/apps/mainnet-apps.yaml`
- Triggers: ArgoCD deployment or manual kubectl apply
- Responsibilities: Initialize environment-specific app-of-apps that deploy all components

**Component Deployment:**
- Location: `nonprod-argocd-config/apps/envs/*/sequencer-app.yaml`, `nonprod-argocd-config/apps/envs/*/validator-*-app.yaml`
- Triggers: Parent app-of-apps synchronization
- Responsibilities: Deploy individual Ten Protocol components with environment-specific configuration

**Helm Chart Templates:**
- Location: `charts/*/templates/*.yaml`
- Triggers: Helm rendering during ArgoCD synchronization
- Responsibilities: Generate Kubernetes manifests from templates and values

## Error Handling

**Strategy:** Progressive deployment with manual/automated rollback capabilities

**Patterns:**
- ArgoCD sync waves ensure proper deployment ordering (annotations like `argocd.argoproj.io/sync-wave: "2"`)
- Health checks and readiness probes for service availability validation
- Persistent volume retention policies prevent data loss during failures
- External secrets integration provides secure credential management

## Cross-Cutting Concerns

**Logging:** Container-based logging with potential Promtail integration (referenced in `docs/PROMTAIL_SETUP.md`)
**Validation:** Helm chart validation and ArgoCD application health checks
**Authentication:** External secrets management with Azure Key Vault integration and SGX-based attestation

---

*Architecture analysis: 2026-02-04*