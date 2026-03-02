#!/bin/bash

set -euo pipefail

NAMESPACE="${NAMESPACE:-feastflow}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE_MANIFEST="${SCRIPT_DIR}/00-namespace.yaml"
PERSISTENCE_MANIFEST="${SCRIPT_DIR}/13-persistence-demo.yaml"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found in current shell PATH."
  echo "Use PowerShell script on Windows: .\\devops\\kubernetes\\verify-persistence.ps1"
  exit 1
fi

echo "============================================================"
echo "FeastFlow Kubernetes Persistent Volume Verification"
echo "Namespace: ${NAMESPACE}"
echo "============================================================"

echo "[1/7] Checking cluster connectivity"
kubectl cluster-info >/dev/null

echo "[2/7] Applying namespace and persistence demo manifest"
kubectl apply -f "${NAMESPACE_MANIFEST}" >/dev/null
kubectl apply -f "${PERSISTENCE_MANIFEST}" >/dev/null

echo "[3/7] Waiting for PVC to bind"
echo "   Ensuring persistence demo pod is created..."
pod_created=false
for _ in $(seq 1 60); do
  pod_name=$(kubectl get pods -n "${NAMESPACE}" -l component=persistence-demo -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  if [[ -n "${pod_name}" ]]; then
    pod_created=true
    break
  fi
  sleep 2
done

if [[ "${pod_created}" != "true" ]]; then
  echo "ERROR: Persistence demo pod was not created in time"
  kubectl get deployment feastflow-persistence-demo -n "${NAMESPACE}" -o wide || true
  kubectl get pods -n "${NAMESPACE}" -l component=persistence-demo -o wide || true
  kubectl get events -n "${NAMESPACE}" --sort-by=.lastTimestamp | tail -n 20 || true
  exit 1
fi

echo "   Waiting for pod scheduling (required by WaitForFirstConsumer)..."
pod_scheduled=false
for _ in $(seq 1 90); do
  scheduled_node=$(kubectl get pods -n "${NAMESPACE}" -l component=persistence-demo -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null || true)
  if [[ -n "${scheduled_node}" ]]; then
    pod_scheduled=true
    break
  fi
  sleep 2
done

if [[ "${pod_scheduled}" != "true" ]]; then
  echo "ERROR: Persistence demo pod was not scheduled in time"
  kubectl get nodes -o wide || true
  kubectl get pods -n "${NAMESPACE}" -l component=persistence-demo -o wide || true
  pod_name=$(kubectl get pods -n "${NAMESPACE}" -l component=persistence-demo -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  if [[ -n "${pod_name}" ]]; then
    kubectl describe pod "${pod_name}" -n "${NAMESPACE}" || true
  fi
  kubectl get events -n "${NAMESPACE}" --sort-by=.lastTimestamp | tail -n 20 || true
  exit 1
fi

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/persistence-demo-pvc -n "${NAMESPACE}" --timeout=300s >/dev/null
if [[ $? -ne 0 ]]; then
  echo "ERROR: PVC persistence-demo-pvc did not reach Bound state"
  kubectl get pvc persistence-demo-pvc -n "${NAMESPACE}" -o wide || true
  kubectl describe pvc persistence-demo-pvc -n "${NAMESPACE}" || true
  exit 1
fi
pvc_status=$(kubectl get pvc persistence-demo-pvc -n "${NAMESPACE}" -o jsonpath='{.status.phase}')
echo "PVC status: ${pvc_status}"

echo "[4/7] Waiting for demo pod readiness"
kubectl rollout status deployment/feastflow-persistence-demo -n "${NAMESPACE}" --timeout=180s >/dev/null
kubectl wait --for=condition=Ready pod -l component=persistence-demo -n "${NAMESPACE}" --timeout=180s >/dev/null
old_pod=$(kubectl get pods -n "${NAMESPACE}" -l component=persistence-demo --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
echo "Current pod: ${old_pod}"

echo "[5/7] Writing marker data to mounted volume"
marker="persist-proof-$(date +%Y%m%d%H%M%S)"
kubectl exec -n "${NAMESPACE}" "${old_pod}" -- sh -c "echo '${marker}' > /data/proof.txt; sync"
written=$(kubectl exec -n "${NAMESPACE}" "${old_pod}" -- cat /data/proof.txt)
echo "Marker written: ${written}"

echo "[6/7] Deleting pod to simulate restart"
kubectl delete pod "${old_pod}" -n "${NAMESPACE}" --wait=false >/dev/null
kubectl wait --for=delete "pod/${old_pod}" -n "${NAMESPACE}" --timeout=180s >/dev/null
kubectl wait --for=condition=Ready pod -l component=persistence-demo -n "${NAMESPACE}" --timeout=180s >/dev/null
new_pod=$(kubectl get pods -n "${NAMESPACE}" -l component=persistence-demo --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
if [[ -z "${new_pod}" || "${new_pod}" == "${old_pod}" ]]; then
  new_pod=$(kubectl get pods -n "${NAMESPACE}" -l component=persistence-demo --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v "^${old_pod}$" | head -n 1)
fi
echo "New pod: ${new_pod}"

echo "[7/7] Reading marker after restart"
after_restart=$(kubectl exec -n "${NAMESPACE}" "${new_pod}" -- cat /data/proof.txt)
echo "Marker after restart: ${after_restart}"

if [[ "${after_restart}" != "${marker}" ]]; then
  echo "ERROR: Persistence check failed: expected '${marker}' but got '${after_restart}'"
  exit 1
fi

echo ""
echo "✅ Persistence verified: data survived pod restart using PVC."
echo "   PVC: persistence-demo-pvc"
echo "   Pod replaced: ${old_pod} -> ${new_pod}"
