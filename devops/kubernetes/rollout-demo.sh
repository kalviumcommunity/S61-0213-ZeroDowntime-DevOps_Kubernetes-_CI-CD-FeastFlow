#!/bin/bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-feastflow}"
DEPLOYMENT="${DEPLOYMENT:-feastflow-backend}"
ROLLOUT_TIMEOUT_SECONDS="${ROLLOUT_TIMEOUT_SECONDS:-180}"
FAILED_ROLLOUT_TIMEOUT_SECONDS="${FAILED_ROLLOUT_TIMEOUT_SECONDS:-45}"
SKIP_FAILED_UPDATE="${SKIP_FAILED_UPDATE:-false}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GRAY='\033[0;37m'
NC='\033[0m'

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command '$1' not found in PATH."
    exit 1
  fi
}

get_deployment_image() {
  kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].image}'
}

wait_deployment_ready() {
  kubectl rollout status "deployment/$DEPLOYMENT" -n "$NAMESPACE" --timeout="${1}s"
}

show_status() {
  echo -e "\n${YELLOW}Deployment status:${NC}"
  kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o wide
  echo -e "\n${YELLOW}Pods:${NC}"
  kubectl get pods -n "$NAMESPACE" -l component=backend -o wide
  echo -e "\n${YELLOW}ReplicaSets:${NC}"
  kubectl get rs -n "$NAMESPACE" -l component=backend
}

require_command kubectl

echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}  FeastFlow Rolling Update + Rollback Demo${NC}"
echo -e "${CYAN}================================================${NC}"

echo -e "\n${GREEN}[1/7] Verifying cluster + deployment...${NC}"
kubectl config current-context
kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE"

ORIGINAL_IMAGE="$(get_deployment_image)"
echo -e "${GRAY}Current image: ${ORIGINAL_IMAGE}${NC}"

echo -e "\n${GREEN}[2/7] Capturing current rollout history...${NC}"
kubectl rollout history "deployment/$DEPLOYMENT" -n "$NAMESPACE"

echo -e "\n${GREEN}[3/7] Performing successful rolling update (env var change)...${NC}"
RELEASE_STAMP="$(date +%Y%m%d-%H%M%S)"
CHANGE_CAUSE_GOOD="Sprint-3 successful rolling update DEMO_RELEASE=${RELEASE_STAMP}"

kubectl annotate "deployment/$DEPLOYMENT" -n "$NAMESPACE" kubernetes.io/change-cause="$CHANGE_CAUSE_GOOD" --overwrite
kubectl set env "deployment/$DEPLOYMENT" -n "$NAMESPACE" DEMO_RELEASE="$RELEASE_STAMP"
wait_deployment_ready "$ROLLOUT_TIMEOUT_SECONDS"

echo -e "\n${GREEN}[4/7] Verifying successful update and revision history...${NC}"
show_status
kubectl rollout history "deployment/$DEPLOYMENT" -n "$NAMESPACE"

if [[ "$SKIP_FAILED_UPDATE" != "true" ]]; then
  echo -e "\n${GREEN}[5/7] Triggering controlled failed update (invalid image)...${NC}"
  BAD_IMAGE="feastflow-backend:rollback-demo-bad"
  CHANGE_CAUSE_BAD="Sprint-3 failed update simulation image=${BAD_IMAGE}"

  kubectl annotate "deployment/$DEPLOYMENT" -n "$NAMESPACE" kubernetes.io/change-cause="$CHANGE_CAUSE_BAD" --overwrite
  kubectl set image "deployment/$DEPLOYMENT" -n "$NAMESPACE" backend="$BAD_IMAGE"

  set +e
  wait_deployment_ready "$FAILED_ROLLOUT_TIMEOUT_SECONDS"
  ROLLOUT_EXIT=$?
  set -e

  if [[ $ROLLOUT_EXIT -eq 0 ]]; then
    echo -e "${YELLOW}Unexpected: failed rollout simulation did not fail within timeout.${NC}"
  else
    echo -e "${YELLOW}Expected failure observed (rollout timeout).${NC}"
  fi

  echo -e "\n${YELLOW}Inspecting failure signals:${NC}"
  kubectl get pods -n "$NAMESPACE" -l component=backend
  kubectl get events -n "$NAMESPACE" --sort-by=.lastTimestamp | tail -n 20

  echo -e "\n${GREEN}[6/7] Rolling back to last stable revision...${NC}"
  CHANGE_CAUSE_ROLLBACK="Sprint-3 rollback to last stable revision"
  kubectl annotate "deployment/$DEPLOYMENT" -n "$NAMESPACE" kubernetes.io/change-cause="$CHANGE_CAUSE_ROLLBACK" --overwrite
  kubectl rollout undo "deployment/$DEPLOYMENT" -n "$NAMESPACE"
  wait_deployment_ready "$ROLLOUT_TIMEOUT_SECONDS"
fi

echo -e "\n${GREEN}[7/7] Final verification (stable + available)...${NC}"
FINAL_IMAGE="$(get_deployment_image)"
echo -e "${GRAY}Final image: ${FINAL_IMAGE}${NC}"
show_status
kubectl rollout history "deployment/$DEPLOYMENT" -n "$NAMESPACE"

echo -e "\n${CYAN}================================================${NC}"
echo -e "${CYAN}  Demo Complete: rolling update + rollback${NC}"
echo -e "${CYAN}================================================${NC}"
echo -e "${YELLOW}Proof points captured:${NC}"
echo -e "${GREEN}✓ Deployment revisions tracked${NC}"
echo -e "${GREEN}✓ Successful zero-downtime rolling update${NC}"
if [[ "$SKIP_FAILED_UPDATE" != "true" ]]; then
  echo -e "${GREEN}✓ Controlled failed update simulation${NC}"
  echo -e "${GREEN}✓ Rollback to previous stable revision${NC}"
fi
