# Codebase Structure

**Analysis Date:** 2026-02-04

## Directory Layout

```
ten-apps/
├── charts/                     # Helm Charts for Kubernetes applications
├── nonprod-argocd-config/      # Non-production GitOps configurations
├── prod-argocd-config/         # Production GitOps configurations
├── docs/                       # Documentation and operational guides
├── scripts/                    # Operational scripts and utilities
├── ten-network-backup-video/   # Video production assets
├── .planning/                  # AI planning and analysis documents
└── .git/                       # Git repository metadata
```

## Directory Purposes

**charts:**
- Purpose: Helm chart definitions for Ten Protocol infrastructure components
- Contains: Application charts, templates, values files, dependencies
- Key files: `ten-node/Chart.yaml`, `ten-tools/Chart.yaml`, `ten-gateway/Chart.yaml`, `monitoring-stack/Chart.yaml`

**nonprod-argocd-config:**
- Purpose: GitOps configurations for non-production environments (UAT, Sepolia, Dev)
- Contains: ArgoCD Application definitions, environment-specific configurations
- Key files: `apps/uat-apps.yaml`, `apps/sepolia-apps.yaml`, `apps/dev-apps.yaml`

**prod-argocd-config:**
- Purpose: GitOps configurations for production environments (Mainnet)
- Contains: Production ArgoCD Application definitions and mainnet configurations
- Key files: `apps/mainnet-apps.yaml`, `apps/envs/mainnet/`

**docs:**
- Purpose: Operational documentation, deployment guides, and procedural documentation
- Contains: Deployment patterns, backup procedures, disaster recovery playbooks
- Key files: `ARGOCD-DEPLOYMENT-PATTERN.md`, `DISASTER_RECOVERY_PLAYBOOK.md`, `BACKUP_PROCEDURES.md`

**scripts:**
- Purpose: Operational automation scripts and key management utilities
- Contains: Backup scripts, key generation, disaster recovery automation
- Key files: `generate-keys.sh`, `test-backup-restore.sh`, `decrypt-backup.go`

**ten-network-backup-video:**
- Purpose: Video production project for Ten Network content
- Contains: Video source files, rendering outputs, Node.js project structure
- Key files: `src/scenes/`, `out/`, `package.json`

## Key File Locations

**Entry Points:**
- `nonprod-argocd-config/apps/uat-apps.yaml`: UAT environment bootstrap
- `nonprod-argocd-config/apps/sepolia-apps.yaml`: Sepolia testnet bootstrap
- `prod-argocd-config/apps/mainnet-apps.yaml`: Mainnet production bootstrap

**Configuration:**
- `charts/ten-node/values.yaml`: Default Ten Protocol node configuration
- `charts/ten-tools/values.yaml`: Default supporting tools configuration
- `nonprod-argocd-config/apps/envs/*/valuesFile/`: Environment-specific overrides

**Core Logic:**
- `charts/ten-node/templates/enclave-statefulset.yaml`: SGX enclave deployment
- `charts/ten-node/templates/host-deployment.yaml`: L2 node host deployment
- `charts/ten-tools/templates/tenscan-*`: Block explorer components

**Testing:**
- `scripts/test-backup-restore.sh`: Backup/restore validation
- `charts/*/templates/tests/`: Helm chart test definitions

## Naming Conventions

**Files:**
- Helm templates: `kebab-case.yaml` (e.g., `enclave-statefulset.yaml`)
- Values files: `values-{env}-{component}.yaml` (e.g., `values-uat-sequencer.yaml`)
- ArgoCD apps: `{component}-app.yaml` or `{env}-apps.yaml`

**Directories:**
- Chart directories: `kebab-case` (e.g., `ten-node`, `ten-tools`)
- Environment directories: `lowercase` (e.g., `uat`, `sepolia`, `mainnet`)

## Where to Add New Code

**New Helm Chart:**
- Primary code: `charts/{new-chart-name}/`
- Templates: `charts/{new-chart-name}/templates/`
- Default values: `charts/{new-chart-name}/values.yaml`

**New Environment:**
- ArgoCD app: `{nonprod|prod}-argocd-config/apps/{env}-apps.yaml`
- Component apps: `{nonprod|prod}-argocd-config/apps/envs/{env}/`
- Values files: `{nonprod|prod}-argocd-config/apps/envs/{env}/valuesFile/`

**New Component in Existing Environment:**
- App definition: `{nonprod|prod}-argocd-config/apps/envs/{env}/{component}-app.yaml`
- Values file: `{nonprod|prod}-argocd-config/apps/envs/{env}/valuesFile/values-{env}-{component}.yaml`

**Operational Scripts:**
- Shared utilities: `scripts/`
- Key management: `scripts/keys/`

**Documentation:**
- Deployment guides: `docs/`
- Operational procedures: `docs/`

## Special Directories

**charts/*/charts:**
- Purpose: Helm chart dependencies (subchart storage)
- Generated: Yes (by Helm dependency management)
- Committed: No (typically excluded via .gitignore)

**ten-network-backup-video/node_modules:**
- Purpose: Node.js package dependencies for video project
- Generated: Yes (by npm install)
- Committed: No (excluded in .gitignore)

**ten-network-backup-video/out:**
- Purpose: Rendered video output files
- Generated: Yes (by video rendering process)
- Committed: No (build artifacts)

**.planning:**
- Purpose: AI-generated planning and analysis documents
- Generated: Yes (by GSD codebase mapping)
- Committed: Yes (planning artifacts are version controlled)

**charts/*/files:**
- Purpose: Static configuration files embedded in Helm charts
- Generated: No (manually maintained configuration)
- Committed: Yes (required for chart functionality)

---

*Structure analysis: 2026-02-04*