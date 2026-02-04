# Testing Patterns

**Analysis Date:** 2026-02-04

## Test Framework

**Runner:**
- No formal test framework detected for TypeScript/React code
- Go testing uses standard `go test` (implied by go.mod structure)
- Shell script testing via `test-backup-restore.sh`

**Assertion Library:**
- Shell script assertions via exit codes and conditional checks

**Run Commands:**
```bash
./test-backup-restore.sh      # Complete backup/restore test
go run decrypt-backup.go      # Manual decryption test
```

## Test File Organization

**Location:**
- Manual testing approach - no automated test files found
- Integration tests via shell scripts in `scripts/` directory

**Naming:**
- Test scripts: `test-backup-restore.sh`
- Test keys: `test_backup_key_private.pem`, `test_backup_key_public.pem`

**Structure:**
```
scripts/
├── test-backup-restore.sh    # Complete test procedure
├── keys/                     # Test key materials
│   ├── test_backup_key_private.pem
│   └── test_backup_key_public.pem
└── decrypt-backup.go         # Decryption tool
```

## Test Structure

**Suite Organization:**
```bash
# Shell script test structure
echo -e "${YELLOW}Step 1: Generating test backup keys...${NC}"
./generate-keys.sh "$TEST_KEY_NAME"

if [ ! -f "$PRIVATE_KEY_PATH" ]; then
    echo -e "${RED}❌ Failed to generate private key${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Test keys generated successfully${NC}"
```

**Patterns:**
- Setup: Key generation and test data creation
- Execution: Encryption/decryption operations
- Verification: File existence and output validation
- Color-coded output for test results

## Mocking

**Framework:** Not used

**Patterns:**
- Test data generation: `TEST_SHARED_SECRET="abcdef123..."`
- Hardcoded test values for reproducible testing

**What to Mock:**
- Not applicable - integration testing approach

**What NOT to Mock:**
- Cryptographic operations (real encryption/decryption tested)

## Fixtures and Factories

**Test Data:**
```bash
# Simulate shared secret (64 bytes)
TEST_SHARED_SECRET="abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"

# Test configuration
TEST_KEY_NAME="test_backup_key"
KEYS_DIR="./keys"
```

**Location:**
- Test fixtures in `scripts/keys/` directory
- Inline test data in shell scripts

## Coverage

**Requirements:** None enforced

**View Coverage:**
```bash
# No automated coverage tools detected
# Manual verification through shell script execution
```

## Test Types

**Unit Tests:**
- None detected for TypeScript/React components

**Integration Tests:**
- `test-backup-restore.sh`: Complete backup/restore workflow
- `decrypt-backup.go`: Cryptographic operation testing

**E2E Tests:**
- Manual testing approach via shell scripts

## Common Patterns

**Async Testing:**
- Not applicable for current codebase

**Error Testing:**
```bash
# Shell script error handling
set -e  # Exit on error

if [ ! -f "$PRIVATE_KEY_PATH" ]; then
    echo -e "${RED}❌ Failed to generate private key${NC}"
    exit 1
fi
```

**Dependency Checking:**
```bash
# Validate required tools
command -v openssl >/dev/null 2>&1 || { echo "❌ openssl is required"; exit 1; }
command -v go >/dev/null 2>&1 || { echo "❌ go is required"; exit 1; }
```

---

*Testing analysis: 2026-02-04*