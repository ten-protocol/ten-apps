# Codebase Concerns

**Analysis Date:** 2026-02-04

## Tech Debt

**Destructive Deployment Configuration:**
- Issue: `destructiveDeployment: true` enabled across all environments including production-like configs
- Files: `charts/ten-node/values.yaml`, `nonprod-argocd-config/apps/envs/*/valuesFile/*.yaml`, `prod-argocd-config/apps/envs/mainnet/valuesFile/*.yaml`
- Impact: Allows forceful deletion of PVCs and stateful resources during upgrades, potential data loss
- Fix approach: Disable for production environments, implement safer upgrade strategies

**Latest Tag Usage:**
- Issue: Widespread use of `:latest` image tags in production configurations
- Files: `charts/ten-node/values.yaml`, `charts/ten-tools/values.yaml`, `charts/ten-gateway/values.yaml`, all environment value files
- Impact: Unpredictable deployments, inability to rollback, potential production instability
- Fix approach: Pin to specific versions, implement proper tagging strategy

**Obsolete Docker Images:**
- Issue: Using deprecated `bitnamilegacy/kubectl` image
- Files: `charts/ten-node/values.yaml:427`
- Impact: Security vulnerabilities, lack of updates, eventual image unavailability
- Fix approach: Migrate to official kubectl image or current bitnami/kubectl

## Known Bugs

**Empty Authentication Credentials:**
- Symptoms: Empty username/password in Loki authentication configuration
- Files: `nonprod-argocd-config/apps/envs/testnet/promtail-app.yaml:24-25`
- Trigger: Authentication will fail when Promtail tries to connect to Loki
- Workaround: Manual secret creation required as documented in comments

**Placeholder Configurations:**
- Symptoms: Production configs contain placeholder values like "YOUR_FAUCET_PRIVATE_KEY"
- Files: `nonprod-argocd-config/apps/envs/*/valuesFile/values-*-tools.yaml:14-15`
- Trigger: Services will fail to start with invalid credentials
- Workaround: Values must be replaced with actual secrets before deployment

## Security Considerations

**Database Connection URLs:**
- Risk: "REPLACE_ME" placeholders in production database configurations
- Files: `nonprod-argocd-config/apps/envs/*/valuesFile/values-*-gateway.yaml:47-49`, `prod-argocd-config/apps/envs/mainnet/valuesFile/values-mainnet-gateway.yaml:49`
- Current mitigation: None - deployments will fail
- Recommendations: Implement proper secret management, use Kubernetes secrets or external secret operators

**Hardcoded Placeholder Secrets:**
- Risk: Placeholder private keys and JWT secrets in configuration files
- Files: `charts/ten-tools/values.yaml:16-17`, multiple environment configs
- Current mitigation: Values should be overridden at deployment
- Recommendations: Remove placeholders, enforce secret validation, use external secret management

**Debug Namespaces Enabled:**
- Risk: Debug namespaces enabled in production-like environments
- Files: `nonprod-argocd-config/apps/envs/testnet/valuesFile/*.yaml`, `nonprod-argocd-config/apps/envs/uat/valuesFile/*.yaml`
- Current mitigation: None
- Recommendations: Disable debug features in production environments

## Performance Bottlenecks

**Large Configuration Files:**
- Problem: Extremely large YAML configuration files (400+ lines)
- Files: `charts/ten-node/values.yaml:434`, `nonprod-argocd-config/apps/envs/uat/valuesFile/values-uat-eth-node.yaml:241`
- Cause: Monolithic configuration structure with multiple services in single files
- Improvement path: Split into modular configurations, use Helm sub-charts

**TLS Verification Disabled:**
- Problem: TLS verification disabled for Loki connections
- Files: `nonprod-argocd-config/apps/envs/testnet/promtail-app.yaml:22`
- Cause: Certificate configuration issues
- Improvement path: Implement proper certificate management

## Fragile Areas

**SGX PCCS Configuration:**
- Files: `charts/ten-node/values.yaml:101,369`
- Why fragile: Empty PCCS URLs disable SGX attestation, critical security feature
- Safe modification: Ensure proper PCCS service configuration before enabling
- Test coverage: Manual verification required for SGX functionality

**PVC Cleanup Jobs:**
- Files: `charts/ten-node/templates/pvc-cleanup-job.yaml:43-44`
- Why fragile: Forces PVC deletion by removing finalizers, bypasses Kubernetes safety mechanisms
- Safe modification: Implement proper PVC lifecycle management
- Test coverage: Limited testing of cleanup scenarios

**External Secret Mappings:**
- Files: `nonprod-argocd-config/apps/envs/*/valuesFile/*.yaml` (secretMappings sections)
- Why fragile: Hard dependency on external secret names and keys
- Safe modification: Validate secret existence before deployment
- Test coverage: No automated validation of secret availability

## Scaling Limits

**Memory Resource Allocation:**
- Current capacity: 4Gi memory limits per enclave
- Limit: Fixed resource allocation may not scale with transaction volume
- Scaling path: Implement horizontal scaling or dynamic resource allocation

**Storage Configuration:**
- Current capacity: 1Gi default storage for enclave data
- Limit: Fixed storage allocation for blockchain data
- Scaling path: Implement storage auto-scaling or larger default allocations

## Dependencies at Risk

**Container Registry Dependency:**
- Risk: Single point of failure on `testnetobscuronet.azurecr.io`
- Impact: All deployments fail if registry is unavailable
- Migration plan: Implement multi-registry strategy or registry mirroring

**Bitnami Legacy Images:**
- Risk: Deprecated image repository may become unavailable
- Impact: kubectl-based jobs will fail
- Migration plan: Update to current bitnami/kubectl or official kubectl images

## Missing Critical Features

**Secret Validation:**
- Problem: No validation of required secrets before deployment
- Blocks: Automated deployments, prevents early failure detection

**Environment-Specific Security:**
- Problem: Same security configuration across all environments
- Blocks: Proper security hardening for production

## Test Coverage Gaps

**Configuration Validation:**
- What's not tested: YAML configuration syntax and value validation
- Files: All `valuesFile/*.yaml` configurations
- Risk: Invalid configurations deployed to production
- Priority: High

**Secret Management Integration:**
- What's not tested: External secret operator functionality
- Files: All files with `externalSecrets` configurations
- Risk: Secret injection failures in production
- Priority: High

**Destructive Operations:**
- What's not tested: PVC cleanup and destructive deployment scenarios
- Files: `charts/ten-node/templates/pvc-cleanup-job.yaml`
- Risk: Data loss during upgrades
- Priority: Medium

---

*Concerns audit: 2026-02-04*