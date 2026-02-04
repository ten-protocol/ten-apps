# Roadmap: Ten Network Shared Secret Backup System

## Overview

This roadmap delivers a production-ready shared secret backup system for the Ten network, progressing from foundation setup through security validation. The system will enable disaster recovery for both network consensus secrets and gateway encryption keys using SLIP-39 threshold cryptography with Trezor Safe 3 hardware security.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation Setup** - SLIP-39 tooling and Kubernetes infrastructure
- [ ] **Phase 2: Network Secret Backup** - Shared secret backup and recovery for consensus
- [ ] **Phase 3: Gateway Key Backup** - Database encryption key backup and recovery
- [ ] **Phase 4: Operations Integration** - Procedures, tooling, and documentation
- [ ] **Phase 5: Security Hardening** - Access controls, encryption, and hardware security
- [ ] **Phase 6: Testing & Validation** - Comprehensive testing and security validation

## Phase Details

### Phase 1: Foundation Setup
**Goal**: UAT backup system with existing Go tools integrated into Kubernetes deployment infrastructure
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03
**Success Criteria** (what must be TRUE):
  1. UAT operators can generate backup keys using scripts/generate-keys.sh
  2. Go decryption tool (scripts/decrypt-backup.go) works with generated keys
  3. Backup system integrates with UAT Kubernetes environment
  4. Test procedure (scripts/test-backup-restore.sh) validates complete cycle
**Plans**: 2 plans

Plans:
- [ ] 01-01-PLAN.md — Create Kubernetes deployment infrastructure for UAT backup tools
- [ ] 01-02-PLAN.md — Create automated test infrastructure for backup/restore validation

### Phase 2: Network Secret Backup
**Goal**: Ten network consensus shared secrets can be backed up and recovered using threshold cryptography
**Depends on**: Phase 1
**Requirements**: NETBK-01, NETBK-02, NETBK-03
**Success Criteria** (what must be TRUE):
  1. Backup creation via ten_BackupSharedSecret API produces encrypted backup files
  2. Encrypted backups split into 2-of-3 SLIP-39 shares with guardian distribution
  3. Network can restart successfully using shared secret reconstructed from 2 shares
  4. Recovery process validates secret integrity before network restart
**Plans**: 2 plans

Plans:
- [ ] 02-01-PLAN.md — Network secret backup with simple UAT secret sharing
- [ ] 02-02-PLAN.md — Network recovery procedure using reconstructed shared secrets

### Phase 3: Gateway Key Backup
**Goal**: Gateway database encryption keys backed up and recoverable independently from network secrets
**Depends on**: Phase 2
**Requirements**: GWBK-01, GWBK-02, GWBK-03
**Success Criteria** (what must be TRUE):
  1. Gateway encryption keys backed up via /admin/backup-encryption-key/ endpoint
  2. Each gateway instance has independent 2-of-3 SLIP-39 share distribution
  3. Gateway instances restart with recovered encryption keys using -encryptionKeySource
  4. Multiple gateway recovery coordinated without cross-contamination
**Plans**: 2 plans

Plans:
- [ ] 03-01-PLAN.md — Gateway key backup and SLIP-39 share distribution with instance isolation
- [ ] 03-02-PLAN.md — Gateway recovery procedures and multi-instance validation testing

### Phase 4: Operations Integration
**Goal**: Complete operational procedures and tooling for production backup management
**Depends on**: Phase 3
**Requirements**: OPS-01, OPS-02, OPS-03
**Success Criteria** (what must be TRUE):
  1. Multi-party key ceremonies conducted with documented guardian verification
  2. Backup validation tools verify integrity without exposing secrets
  3. Recovery procedures enable complete disaster recovery in under 2 hours
  4. Operations team trained and certified on all backup/recovery procedures
**Plans**: TBD

Plans:
- [ ] 04-01: TBD
- [ ] 04-02: TBD

### Phase 5: Security Hardening
**Goal**: Production-grade security controls and access management for backup operations
**Depends on**: Phase 4
**Requirements**: SEC-01, SEC-02, SEC-03
**Success Criteria** (what must be TRUE):
  1. All key generation requires Trezor Safe 3 hardware with attestation verification
  2. Backup encryption using enclave.backupEncryptionKey prevents unauthorized access
  3. Role-based access controls limit backup operations to authorized personnel only
  4. Complete audit trail captures all backup and recovery activities
**Plans**: TBD

Plans:
- [ ] 05-01: TBD
- [ ] 05-02: TBD

### Phase 6: Testing & Validation
**Goal**: Comprehensive testing validates system security and operational readiness
**Depends on**: Phase 5
**Requirements**: TEST-01, TEST-02, TEST-03
**Success Criteria** (what must be TRUE):
  1. Automated tests verify backup/recovery cycles under various failure scenarios
  2. Complete disaster recovery demonstrated in UAT environment
  3. Security testing confirms threshold cryptography and hardware security integrity
  4. Performance testing validates backup operations under production load conditions
**Plans**: TBD

Plans:
- [ ] 06-01: TBD
- [ ] 06-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation Setup | 0/2 | Not started | - |
| 2. Network Secret Backup | 0/2 | Not started | - |
| 3. Gateway Key Backup | 0/2 | Not started | - |
| 4. Operations Integration | 0/TBD | Not started | - |
| 5. Security Hardening | 0/TBD | Not started | - |
| 6. Testing & Validation | 0/TBD | Not started | - |