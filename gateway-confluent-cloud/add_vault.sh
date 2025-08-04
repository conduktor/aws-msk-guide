#!/bin/bash

# ---- prerequisites ---------------------------------------------------------
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/prerequisites_check.sh"

REQUIRED_COMMANDS=(helm kubectl)
REQUIRED_RUNTIME_TESTS=(
  "kubectl version --client"        # just proves kubectl works
  "kubectl auth can-i create namespace --quiet"  # RBAC probe (no warning)
  "helm version"                    # Helm binary / plugin sanity
)
ensure_prerequisites || exit 1
# ---------------------------------------------------------------------------

helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
# helm install vault hashicorp/vault --set "server.dev.enabled=true"

helm install vault hashicorp/vault -n conduktor \
  --set server.dev.enabled=true \
  --set server.extraEnvironmentVars.VAULT_DEV_ROOT_TOKEN_ID="vault-plaintext-root-token" \
  --set server.extraEnvironmentVars.VAULT_ADDR="http://0.0.0.0:8200" \
  --set server.extraArgs="-dev-listen-address=0.0.0.0:8200" \
  --set ui.enabled=true

sleep 15

kubectl exec -it vault-0 -n conduktor -- sh -c "
  export VAULT_ADDR=http://127.0.0.1:8200
  export VAULT_TOKEN=vault-plaintext-root-token
  vault secrets enable transit
  vault secrets enable -version=1 kv
  vault secrets enable totp
"
