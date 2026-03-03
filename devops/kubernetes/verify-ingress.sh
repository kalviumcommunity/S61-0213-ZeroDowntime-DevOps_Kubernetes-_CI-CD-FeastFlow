#!/bin/bash

set -euo pipefail

HOST_NAME="${HOST_NAME:-feastflow.local}"
BASE_URL="${BASE_URL:-http://localhost}"

echo "=== FeastFlow Ingress Verification ==="

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required but not installed."
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required but not installed."
  exit 1
fi

echo "[1/5] Checking ingress-nginx controller..."
kubectl get deployment ingress-nginx-controller -n ingress-nginx >/dev/null

echo "[2/5] Checking FeastFlow ingress resource..."
kubectl get ingress feastflow-ingress -n feastflow >/dev/null

echo "[3/5] Showing ingress summary"
kubectl get ingress feastflow-ingress -n feastflow

echo "[4/5] Testing frontend route '/'..."
frontend_status="$(curl -s -o /dev/null -w "%{http_code}" -H "Host: ${HOST_NAME}" "${BASE_URL}/")"
if [[ "$frontend_status" -lt 200 || "$frontend_status" -ge 400 ]]; then
  echo "Frontend route failed (status: ${frontend_status})"
  exit 1
fi
echo "Frontend route reachable (status: ${frontend_status})"

echo "[5/5] Testing backend route '/api/health'..."
backend_status="$(curl -s -o /dev/null -w "%{http_code}" -H "Host: ${HOST_NAME}" "${BASE_URL}/api/health")"
if [[ "$backend_status" -lt 200 || "$backend_status" -ge 400 ]]; then
  echo "Backend route failed (status: ${backend_status})"
  exit 1
fi

echo "Backend route reachable (status: ${backend_status})"
echo ""
echo "Ingress routing is working:"
echo "  ${BASE_URL}/             -> feastflow-frontend service"
echo "  ${BASE_URL}/api/health   -> feastflow-backend service"
echo ""
echo "Tip: add '127.0.0.1 ${HOST_NAME}' to /etc/hosts and use http://${HOST_NAME}."
