#!/bin/bash

# ---- prerequisites ---------------------------------------------------------
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/prerequisites_check.sh"

REQUIRED_COMMANDS=(kubectl conduktor jq base64 kafka-console-consumer envsubst)
REQUIRED_RUNTIME_TESTS=(
  "kubectl get secret gateway-conduktor-gateway-secret -n conduktor >/dev/null"
  "kubectl auth can-i get svc -n conduktor"
)
ensure_prerequisites || exit 1
# ---------------------------------------------------------------------------

export ADMIN_PASSWORD="$(kubectl get secret gateway-conduktor-gateway-secret -n conduktor -o jsonpath="{.data.GATEWAY_ADMIN_API_USER_0_PASSWORD}" | base64 --decode | tr -d '\n\r ')"
export LB_DNS=$(kubectl get svc gateway-conduktor-gateway-external -n conduktor -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

export CDK_GATEWAY_BASE_URL=http://$LB_DNS:8888
export CDK_GATEWAY_USER=admin
export CDK_GATEWAY_PASSWORD=$ADMIN_PASSWORD

conduktor apply -f pz_admin_sa.yaml 


export SA_ADMIN_PASSWORD=$(conduktor run generateServiceAccountToken  --life-time-seconds 999999 --username admin --v-cluster passthrough | jq -r .token)

envsubst < adminclient-template.properties > adminclient.properties



kafka-console-consumer --bootstrap-server $LB_DNS:9092 --consumer.config adminclient.properties --topic '_conduktor_default_auditlogs' --from-beginning