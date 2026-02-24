#!/bin/bash

set -euo pipefail

CLUSTER_NAME="feastflow-local"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
K8S_DIR="${ROOT_DIR}/devops/kubernetes"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

echo "🚀 FeastFlow local Kubernetes setup (kind)"

if ! command_exists docker; then
  echo "❌ Docker is required but not installed."
  exit 1
fi

if ! command_exists kind; then
  echo "❌ kind is required but not installed."
  exit 1
fi

if ! command_exists kubectl; then
  echo "❌ kubectl is required but not installed."
  exit 1
fi

echo "🔍 Checking cluster '${CLUSTER_NAME}'..."
if kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  echo "✅ kind cluster '${CLUSTER_NAME}' already exists"
else
  echo "⚙️  Creating kind cluster '${CLUSTER_NAME}'"
  kind create cluster --name "${CLUSTER_NAME}" --config "${K8S_DIR}/kind-cluster.yaml"
fi

kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null

echo "🐳 Building backend image"
docker build -t feastflow-backend:latest "${ROOT_DIR}/backend"

echo "🐳 Building frontend image"
docker build -t feastflow-frontend:latest "${ROOT_DIR}/frontend/app"

echo "📦 Loading images into kind"
kind load docker-image feastflow-backend:latest --name "${CLUSTER_NAME}"
kind load docker-image feastflow-frontend:latest --name "${CLUSTER_NAME}"

echo "📄 Applying Kubernetes manifests"
kubectl apply -f "${K8S_DIR}/00-namespace.yaml"
kubectl apply -f "${K8S_DIR}/01-configmap.yaml"
kubectl apply -f "${K8S_DIR}/02-secrets.yaml"
kubectl apply -f "${K8S_DIR}/03-postgres-pvc.yaml"
kubectl apply -f "${K8S_DIR}/04-postgres-deployment.yaml"
kubectl apply -f "${K8S_DIR}/05-postgres-service.yaml"
kubectl apply -f "${K8S_DIR}/06-backend-deployment.yaml"
kubectl apply -f "${K8S_DIR}/07-backend-service.yaml"
kubectl apply -f "${K8S_DIR}/08-frontend-deployment.yaml"
kubectl apply -f "${K8S_DIR}/09-frontend-service.yaml"
kubectl apply -f "${K8S_DIR}/10-ingress.yaml"

echo "⏳ Waiting for rollouts"
kubectl rollout status statefulset/postgres -n feastflow --timeout=180s
kubectl rollout status deployment/feastflow-backend -n feastflow --timeout=180s
kubectl rollout status deployment/feastflow-frontend -n feastflow --timeout=180s

echo ""
echo "✅ Local cluster is ready and accessible"
echo ""
echo "Run these verification commands:"
echo "  kubectl config current-context"
echo "  kubectl cluster-info"
echo "  kubectl get nodes"
echo "  kubectl get pods -n feastflow"
echo "  kubectl get services -n feastflow"
