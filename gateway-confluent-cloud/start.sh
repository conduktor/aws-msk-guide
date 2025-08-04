#!/bin/bash
#There should be a case that establishes a proper context and show it back to the user or clear the current context if one is already set
#kubectl config current-context
#kubectl config unset current-context


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


# Create shared namespace
kubectl create namespace conduktor

# Add helm repos
helm repo add conduktor https://helm.conduktor.io
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm repo update eks

#make sure you set the vpc id and region 
#https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set region=us-east-1 \
  --set vpcId=vpc-**** \
  --set clusterName=serious-hiphop-sparrow \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller


sleep 30

# Install Gateway
helm install \
    -f ./values.yaml \
    -n conduktor \
    gateway conduktor/conduktor-gateway


sleep 30

# # get the load balancer url

export LB_DNS=$(kubectl get svc gateway-conduktor-gateway-external -n conduktor -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo $LB_DNS


# # update the gateway advertised hostname
kubectl set env deployment/gateway-conduktor-gateway -n conduktor GATEWAY_ADVERTISED_HOST=$LB_DNS               


export CDK_GATEWAY_BASE_URL=$LB_DNS:8888
export CDK_GATEWAY_USER=admin
export CDK_GATEWAY_PASSWORD=$(kubectl get secret gateway-conduktor-gateway-secret -n conduktor -o jsonpath="{.data.GATEWAY_ADMIN_API_USER_0_PASSWORD}" | base64 --decode) 

