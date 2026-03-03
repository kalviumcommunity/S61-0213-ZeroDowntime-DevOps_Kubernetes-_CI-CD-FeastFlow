#!/bin/bash

set -euo pipefail

NAMESPACE="${NAMESPACE:-feastflow}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-feastflow-readonly-sa}"
AS_USER="system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE_MANIFEST="${SCRIPT_DIR}/00-namespace.yaml"
RBAC_MANIFEST="${SCRIPT_DIR}/14-rbac-basics.yaml"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found in current shell PATH."
  exit 1
fi

echo "============================================================"
echo "FeastFlow Kubernetes RBAC Verification"
echo "Namespace: ${NAMESPACE}"
echo "ServiceAccount: ${SERVICE_ACCOUNT}"
echo "============================================================"

echo "[1/5] Checking cluster connectivity"
kubectl cluster-info >/dev/null

echo "[2/5] Applying namespace and RBAC manifest"
kubectl apply -f "${NAMESPACE_MANIFEST}" >/dev/null
kubectl apply -f "${RBAC_MANIFEST}" >/dev/null

echo "[3/5] Verifying allowed access (should be yes)"
allowed_pods=$(kubectl auth can-i --as="${AS_USER}" -n "${NAMESPACE}" list pods)
allowed_deployments=$(kubectl auth can-i --as="${AS_USER}" -n "${NAMESPACE}" get deployments)

echo "can-i list pods: ${allowed_pods}"
echo "can-i get deployments: ${allowed_deployments}"

if [[ "${allowed_pods}" != "yes" || "${allowed_deployments}" != "yes" ]]; then
  echo "ERROR: Expected allowed read actions were denied."
  exit 1
fi

echo "[4/5] Verifying denied access (should be no)"
denied_delete_pods=$(kubectl auth can-i --as="${AS_USER}" -n "${NAMESPACE}" delete pods)
denied_create_secrets=$(kubectl auth can-i --as="${AS_USER}" -n "${NAMESPACE}" create secrets)

echo "can-i delete pods: ${denied_delete_pods}"
echo "can-i create secrets: ${denied_create_secrets}"

if [[ "${denied_delete_pods}" != "no" || "${denied_create_secrets}" != "no" ]]; then
  echo "ERROR: Expected denied write/admin actions were allowed."
  exit 1
fi

echo "[5/5] Triggering one real forbidden action (expected failure)"
set +e
forbidden_output=$(kubectl --as="${AS_USER}" -n "${NAMESPACE}" get secrets 2>&1)
forbidden_exit=$?
set -e

echo "${forbidden_output}"

if [[ ${forbidden_exit} -eq 0 ]]; then
  echo "ERROR: get secrets unexpectedly succeeded."
  exit 1
fi

if [[ "${forbidden_output}" != *"Forbidden"* ]]; then
  echo "ERROR: Forbidden response was expected but not detected."
  exit 1
fi

echo ""
echo "✅ RBAC verified: read-only access allowed, mutating/secret access denied."
echo "   Principal: ${AS_USER}"