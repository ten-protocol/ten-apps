#!/bin/bash
set -e

# UAT Disaster Recovery Test - New Node Scenario
# This script simulates a complete node failure and recovery on a fresh AKS node

NAMESPACE="uat"
NODE_PREFIX="uat-validator-03"
NEW_NODE_SELECTOR="aks-sgxpool-35313246-vmss000007"  # Change to your new node

echo "=================================================="
echo "  UAT DR Test - Recovery on New Node"
echo "=================================================="
echo ""

# === STEP 1: Stop and Delete Existing Deployment ===
echo "[1/7] Stopping existing deployment..."
kubectl scale statefulset ${NODE_PREFIX}-ten-node-enclave -n "$NAMESPACE" --replicas=0
kubectl scale deployment ${NODE_PREFIX}-ten-node-host -n "$NAMESPACE" --replicas=0

echo "Waiting for pods to terminate..."
kubectl wait --for=delete pod -l app.kubernetes.io/part-of=Enclave -n "$NAMESPACE" --timeout=60s 2>/dev/null || true
sleep 5

# === STEP 2: Delete PVCs ===
echo ""
echo "[2/7] Deleting PVCs..."
kubectl delete pvc -n "$NAMESPACE" \
  ${NODE_PREFIX}-ten-node-enclave-enclave \
  ${NODE_PREFIX}-ten-node-enclave-db 2>/dev/null || echo "PVCs already deleted or not found"

sleep 5

# === STEP 3: Delete StatefulSet (keeps claim metadata) ===
echo ""
echo "[3/7] Deleting StatefulSet..."
kubectl delete statefulset ${NODE_PREFIX}-ten-node-enclave -n "$NAMESPACE" --cascade=orphan

sleep 5

# === STEP 4: Update Values File with New Node Selector ===
echo ""
echo "[4/7] Updating node selector to: $NEW_NODE_SELECTOR"
VALUES_FILE="/Users/krish/code/obscuro/ten-apps/nonprod-argocd-config/apps/envs/uat/valuesFile/values-uat-validator-03.yaml"

# Backup current values
cp "$VALUES_FILE" "${VALUES_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

# Update node selectors (both enclave and host)
sed -i '' "s/kubernetes.io\/hostname: aks-sgxpool-35313246-vmss000006/kubernetes.io\/hostname: $NEW_NODE_SELECTOR/g" "$VALUES_FILE"

echo "Values file updated. Backup created."

# === STEP 5: Commit and Push (or sync via ArgoCD) ===
echo ""
echo "[5/7] Committing changes..."
cd /Users/krish/code/obscuro/ten-apps
git add nonprod-argocd-config/apps/envs/uat/valuesFile/values-uat-validator-03.yaml
git commit -m "DR test: move validator-03 to new node $NEW_NODE_SELECTOR"
git push

echo ""
echo "Waiting for ArgoCD to sync (30 seconds)..."
sleep 30

# === STEP 6: Verify New Resources are Created ===
echo ""
echo "[6/7] Verifying new StatefulSet is created..."
kubectl get statefulset -n "$NAMESPACE" | grep validator-03

echo ""
echo "Waiting for pods to be ready on new node..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/part-of=Enclave -n "$NAMESPACE" --timeout=300s

# === STEP 7: Verify Recovery ===
echo ""
echo "[7/7] Verifying recovery..."
echo ""

# Check logs for shared secret usage
echo "Checking enclave logs for shared secret..."
kubectl logs -n "$NAMESPACE" -l app.kubernetes.io/part-of=Enclave -c ten-node-enclave --tail=50 | grep -i "shared" || echo "No shared secret log found (may have scrolled)"

# Check if RPC is responding
echo ""
echo "Checking RPC availability..."
RPC_RESPONSE=$(curl -s -X POST http://uat-validator-03.ten.xyz \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}')

if echo "$RPC_RESPONSE" | grep -q "result"; then
    BLOCK_NUM=$(echo "$RPC_RESPONSE" | jq -r '.result.number')
    echo "✅ RPC Responding! Block: $((16#${BLOCK_NUM}))"

    # Wait a bit and check again to verify syncing
    sleep 10
    RPC_RESPONSE2=$(curl -s -X POST http://uat-validator-03.ten.xyz \
      -H "Content-Type: application/json" \
      -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}')
    BLOCK_NUM2=$(echo "$RPC_RESPONSE2" | jq -r '.result.number')

    if [ "$BLOCK_NUM" != "$BLOCK_NUM2" ]; then
        echo "✅ Node is syncing! Block increased from $((16#${BLOCK_NUM})) to $((16#${BLOCK_NUM2}))"
    fi
else
    echo "❌ RPC not responding yet. Check pod logs:"
    kubectl logs -n "$NAMESPACE" -l app.kubernetes.io/part-of=Enclave --tail=50
fi

echo ""
echo "=================================================="
echo "  DR Test Complete!"
echo "=================================================="
echo ""
echo "To rollback to original node:"
echo "  1. Restore values file from backup"
echo "  2. Commit and push"
echo "  3. Delete StatefulSet/PVCs"
echo "  4. Let ArgoCD recreate on original node"
echo ""
