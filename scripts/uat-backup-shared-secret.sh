#!/bin/bash
set -e

# UAT Shared Secret Backup Script
# This script automates the backup of shared secret from UAT validator-03

# Configuration
VALIDATOR_FQDN="uat-validator-03.ten.xyz"
VALIDATOR_RPC_PORT="80"
KEYVAULT="tenuatkvf763"
SECRET_NAME="uat-validator-03-sharedsecret"

# UAT Backup Private Key (KEEP SECURE!)
PRIVATE_KEY="3b9a5ae02d29043ddd1da29ed688142d03f355517f92fb0f06248e6893324e70"

# Backup tool path
BACKUP_DECRYPT_TOOL="$HOME/code/obscuro/go-ten/tools/backupdecrypt"

echo "=================================================="
echo "  UAT Shared Secret Backup - Validator 03"
echo "=================================================="
echo ""

# Phase 1: Verify validator is ready
echo "[1/4] Verifying validator-03 is reachable..."
curl -s --connect-timeout 5 "http://$VALIDATOR_FQDN:$VALIDATOR_RPC_PORT" > /dev/null
echo "Validator-03 is reachable at $VALIDATOR_FQDN:$VALIDATOR_RPC_PORT"

# Phase 2: Call backup RPC
echo ""
echo "[2/4] Calling ten_BackupSharedSecret RPC..."
RESPONSE=$(curl -s -X POST "http://$VALIDATOR_FQDN:$VALIDATOR_RPC_PORT" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "ten_backupSharedSecret",
    "params": [],
    "id": 1
  }')

echo "RPC Response: $RESPONSE"

# Extract encrypted secret
ENCRYPTED=$(echo "$RESPONSE" | jq -r '.result // .error // empty')

if [ -z "$ENCRYPTED" ] || [ "$ENCRYPTED" = "null" ]; then
    echo "ERROR: Failed to get encrypted shared secret"
    echo "Response: $RESPONSE"
    exit 1
fi

if echo "$ENCRYPTED" | grep -qi "error"; then
    echo "ERROR: RPC returned an error"
    echo "Response: $RESPONSE"
    exit 1
fi

echo "Encrypted backup received: ${ENCRYPTED:0:20}..."

# Phase 3: Decrypt
echo ""
echo "[3/4] Decrypting shared secret..."
cd "$BACKUP_DECRYPT_TOOL"

DECRYPTED=$(go run main.go \
  -private-key "$PRIVATE_KEY" \
  -encrypted "$ENCRYPTED" 2>/dev/null | grep "ENCLAVE_SHAREDSECRET:" | awk '{print $2}')

if [ -z "$DECRYPTED" ]; then
    echo "ERROR: Failed to decrypt shared secret"
    exit 1
fi

echo "Decrypted shared secret: $DECRYPTED"

# Verify length (should be 64 hex chars = 32 bytes)
if [ ${#DECRYPTED} -ne 64 ]; then
    echo "WARNING: Decrypted secret length is ${#DECRYPTED} (expected 64)"
fi

# Phase 4: Store in KeyVault
echo ""
echo "[4/4] Storing in KeyVault..."
az keyvault secret set \
  --vault-name "$KEYVAULT" \
  --name "$SECRET_NAME" \
  --value "$DECRYPTED" \
  --query value -o tsv

echo ""
echo "=================================================="
echo "  Backup Complete!"
echo "=================================================="
echo ""
echo "Shared secret stored in KeyVault:"
echo "  Vault: $KEYVAULT"
echo "  Secret: $SECRET_NAME"
echo "  Value: $DECRYPTED"
echo ""
echo "Save the private key securely for disaster recovery:"
echo "  Private Key: $PRIVATE_KEY"
echo ""
