#!/bin/bash

set -euo pipefail

NAMESPACE="${NAMESPACE:-feastflow}"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found in current shell PATH."
  echo "Use PowerShell script on Windows: .\\devops\\kubernetes\\verify-resource-management.ps1"
  exit 1
fi

echo "============================================================"
echo "FeastFlow Kubernetes Resource Management Verification"
echo "Namespace: ${NAMESPACE}"
echo "============================================================"

echo "[1/6] Checking cluster connectivity"
kubectl cluster-info >/dev/null

echo "[2/6] Applying namespace, config, storage, and workloads"
kubectl apply -f devops/kubernetes/00-namespace.yaml >/dev/null
kubectl apply -f devops/kubernetes/01-configmap.yaml >/dev/null
kubectl apply -f devops/kubernetes/02-secrets.yaml >/dev/null
kubectl apply -f devops/kubernetes/03-postgres-pvc.yaml >/dev/null
kubectl apply -f devops/kubernetes/04-postgres-deployment.yaml >/dev/null
kubectl apply -f devops/kubernetes/06-backend-deployment.yaml >/dev/null
kubectl apply -f devops/kubernetes/08-frontend-deployment.yaml >/dev/null

echo "[3/6] Verifying requests/limits are defined on workload specs"
for workload in \
  "statefulset/postgres component=database" \
  "deployment/feastflow-backend component=backend" \
  "deployment/feastflow-frontend component=frontend"; do
  kind_name="${workload%% *}"
  selector="${workload##* }"
  requests=$(kubectl get "${kind_name}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].resources.requests}')
  limits=$(kubectl get "${kind_name}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].resources.limits}')
  echo "${kind_name} -> requests=${requests} limits=${limits}"
  if [[ -z "${requests}" || -z "${limits}" || "${requests}" == "map[]" || "${limits}" == "map[]" ]]; then
    echo "ERROR: Missing requests/limits on ${kind_name}"
    exit 1
  fi
done

echo "[4/6] Verifying pods are scheduled (scheduler used requests)"
for selector in "component=database" "component=backend" "component=frontend"; do
  echo ""
  echo "--- ${selector} ---"
  kubectl wait --for=condition=PodScheduled pod -l "${selector}" -n "${NAMESPACE}" --timeout=120s >/dev/null
  pod_name=$(kubectl get pods -n "${NAMESPACE}" -l "${selector}" -o jsonpath='{.items[0].metadata.name}')
  echo "Scheduled pod: ${pod_name}"
done

echo "[5/6] Verifying stability (pods running within limits)"
set +e
kubectl rollout status statefulset/postgres -n "${NAMESPACE}" --timeout=180s
postgres_status=$?
kubectl rollout status deployment/feastflow-backend -n "${NAMESPACE}" --timeout=180s
backend_status=$?
kubectl rollout status deployment/feastflow-frontend -n "${NAMESPACE}" --timeout=180s
frontend_status=$?
set -e

kubectl get pods -n "${NAMESPACE}" -o wide

if [[ ${postgres_status} -ne 0 || ${backend_status} -ne 0 || ${frontend_status} -ne 0 ]]; then
  echo ""
  echo "One or more workloads are not stable yet. Collecting concise failure reasons..."
  for selector in "component=backend" "component=frontend"; do
    pod_name=$(kubectl get pods -n "${NAMESPACE}" -l "${selector}" -o jsonpath='{.items[0].metadata.name}')
    echo ""
    echo "${selector} pod: ${pod_name}"
    kubectl get pod "${pod_name}" -n "${NAMESPACE}" -o jsonpath='Phase: {.status.phase}{"\n"}WaitingReason: {.status.containerStatuses[0].state.waiting.reason}{"\n"}' || true
  done
  echo ""
  echo "Hint: If reason is ErrImageNeverPull/ImagePullBackOff, load local images into kind first:"
  echo "  ./devops/kubernetes/setup-kind.sh"
  exit 1
fi

echo "[6/6] Checking runtime resource usage (if metrics-server is installed)"
if kubectl top pods -n "${NAMESPACE}" >/dev/null 2>&1; then
  kubectl top pods -n "${NAMESPACE}"
else
  echo "metrics-server not available; skipping 'kubectl top'"
fi

echo ""
echo "Verification complete: workloads are scheduled and constrained by defined requests/limits."
