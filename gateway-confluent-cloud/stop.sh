#!/bin/bash

# ── prerequisites -------------------------------------------------------------
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/prerequisites_check.sh"

# 1️⃣ Static checks – binaries you need on the PATH
REQUIRED_COMMANDS=(
  aws             # AWS CLI
  kubectl         # Kubernetes CLI
  helm            # Helm package manager
  jq              # JSON parsing used later in the script
  conduktor       # Conduktor CLI (if start.sh touches CDK)
)

# 2️⃣ Runtime / permission smoke‑tests
REQUIRED_RUNTIME_TESTS=(
  "aws sts get-caller-identity"         # confirms AWS creds/IAM
  "kubectl auth can-i list pods"        # basic RBAC probe
  "helm ls --all-namespaces"            # Helm ↔ cluster reachability
)

ensure_prerequisites || exit 1
# ── prerequisites end ─────────────────────────────────────────────────────────

kubectl delete namespace conduktor
# helm uninstall ingress-nginx ingress-nginx/ingress-nginx
helm uninstall aws-load-balancer-controller -n kube-system
