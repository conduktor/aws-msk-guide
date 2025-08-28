#!/usr/bin/env bash
################################################################################
# prerequisites_check.sh
#
# HOW TO USE
# ----------
#   source /path/to/prerequisites_check.sh
#   REQUIRED_COMMANDS=(aws kubectl helm jq)
#   declare -A REQUIRED_CMD_MIN_VERS=(["jq"]="1.6")
#   REQUIRED_ENV_VARS=(AWS_REGION CDK_API_KEY "CDK_USER,CDK_PASSWORD")
#
#   # Optional runtime / permission tests – succeed (exit 0) or the script aborts
#   REQUIRED_RUNTIME_TESTS=(
#     "aws sts get-caller-identity"        # AWS creds / IAM
#     "kubectl auth can-i list pods"       # kube‑context + RBAC
#     "helm ls --all-namespaces"           # Helm ↔ cluster reachability
#   )
#
#   ensure_prerequisites || exit 1
#
# WHAT IT CHECKS
# --------------
# 1. Each command in REQUIRED_COMMANDS is on $PATH.
# 2. If a minimum version is declared in REQUIRED_CMD_MIN_VERS, the installed
#    version must be >= that minimum.
# 3. Environment variables in REQUIRED_ENV_VARS are set.
#    • Single name          → that var must be non‑empty.
#    • “A,B” (comma)        → ALL listed vars must be non‑empty.
#    • “A|B” (pipe)         → at least ONE of the vars must be non‑empty.
# 4. Every shell snippet in REQUIRED_RUNTIME_TESTS executes successfully.
#    (Great for probing AWS credentials, kubectl/helm RBAC, docker daemon, etc.)
################################################################################

set -o pipefail

_color() { printf "\e[%sm%s\e[0m\n" "$1" "$2"; }

_version_ge() {           # _version_ge <candidate> <minimum>
  [[ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

ensure_prerequisites() {

  local ok=true

  ############# 1. Binary presence & 2. Minimum versions #######################
  for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      _color 31 "✖ Required program '$cmd' not found in \$PATH."
      ok=false
      continue
    fi

    local want="${REQUIRED_CMD_MIN_VERS[$cmd]}"
    if [[ -n "$want" ]]; then
      local have
      have=$("$cmd" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)*' | head -n1)
      if [[ -z "$have" ]]; then
        _color 33 "⚠ Could not determine version of '$cmd'."
      elif ! _version_ge "$have" "$want"; then
        _color 31 "✖ '$cmd' version $have is older than required $want."
        ok=false
      fi
    fi
  done

  ############# 3. Environment variables ######################################
  for spec in "${REQUIRED_ENV_VARS[@]}"; do
    if [[ "$spec" == *","* ]]; then            # ALL must be set
      IFS=',' read -ra vars <<< "$spec"
      local missing=false
      for v in "${vars[@]}"; do
        [[ -z "${!v}" ]] && missing=true
      done
      if $missing; then
        _color 31 "✖ Env vars ${vars[*]} must ALL be set."
        ok=false
      fi

    elif [[ "$spec" == *"|"* ]]; then          # ANY may be set
      IFS='|' read -ra vars <<< "$spec"
      local has_one=false
      for v in "${vars[@]}"; do
        [[ -n "${!v}" ]] && has_one=true
      done
      if ! $has_one; then
        _color 31 "✖ Set at least ONE of: ${vars[*]}"
        ok=false
      fi

    else                                       # single var
      [[ -z "${!spec}" ]] && {
        _color 31 "✖ Env var $spec is not set."
        ok=false
      }
    fi
  done

  ############# 4. Runtime / permission smoke‑tests ###########################
  for test_cmd in "${REQUIRED_RUNTIME_TESTS[@]}"; do
    if ! eval "$test_cmd" >/dev/null 2>&1; then
      _color 31 "✖ Runtime check failed → $test_cmd"
      _color 33 "   (verify credentials / context / RBAC)"
      ok=false
    fi
  done

  ############# 5. Final result ################################################
  if ! $ok; then
    _color 31 "--- Aborting: unmet prerequisites ---"
    return 1
  fi

  _color 32 "✅ All prerequisites satisfied."
  return 0
}

# Self‑test / help if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  cat <<'USAGE'
prerequisites_check.sh is meant to be *sourced*:

  source /path/to/prerequisites_check.sh
  REQUIRED_COMMANDS=(aws kubectl helm)
  REQUIRED_ENV_VARS=(AWS_REGION)
  REQUIRED_RUNTIME_TESTS=( "aws sts get-caller-identity" "kubectl auth can-i list pods" )
  ensure_prerequisites || exit 1
USAGE
fi
