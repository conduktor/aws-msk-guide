#!/bin/bash

# ---- prerequisites ---------------------------------------------------------
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/prerequisites_check.sh"   # ← central gate

REQUIRED_COMMANDS=(conduktor jq docker envsubst)
REQUIRED_RUNTIME_TESTS=(
  "docker ps"                         # Docker daemon reachable
  "conduktor version >/dev/null"      # CLI responds
)
ensure_prerequisites || exit 1
# ---------------------------------------------------------------------------

export SA_TOKEN_PASSWWORD=$(conduktor run generateServiceAccountToken  --life-time-seconds 999999 --username admin --v-cluster passthrough | jq -r .token)

envsubst < shadowtraffic-retail.json > shadowtraffic-config.json

# push shadow traffic
docker run --rm \
  --env-file "$HOME/code/shadowtraffic" \
  -v "$(pwd)/shadowtraffic-config.json:/home/config.json" \
  shadowtraffic/shadowtraffic:latest \
  --config /home/config.json --watch