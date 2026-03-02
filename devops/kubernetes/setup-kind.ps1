# FeastFlow Kubernetes Setup Script for kind (PowerShell)
# This script creates a local Kubernetes cluster and deploys FeastFlow

$ErrorActionPreference = "Stop"

$CLUSTER_NAME = "feastflow-local"
$ROOT_DIR = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$K8S_DIR = Join-Path $ROOT_DIR "devops\kubernetes"
$BACKEND_DIR = Join-Path $ROOT_DIR "backend"
$FRONTEND_DIR = Join-Path $ROOT_DIR "frontend\app"

Write-Host " FeastFlow local Kubernetes setup (kind)" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host " Checking prerequisites..." -ForegroundColor Yellow

if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker is required but not installed." -ForegroundColor Red
    exit 1
}

if (!(Get-Command kind -ErrorAction SilentlyContinue)) {
    $userKindDir = Join-Path $env:USERPROFILE "bin"
    $userKindPath = Join-Path $userKindDir "kind.exe"
    if (Test-Path $userKindPath) {
        if ($env:Path -notlike "*$userKindDir*") {
            $env:Path = "$env:Path;$userKindDir"
        }
    }
}

if (!(Get-Command kind -ErrorAction SilentlyContinue)) {
    Write-Host " kind is required but not installed." -ForegroundColor Red
    exit 1
}

if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "kubectl is required but not installed." -ForegroundColor Red
    exit 1
}

Write-Host "All prerequisites met" -ForegroundColor Green
Write-Host ""

# Check if cluster exists
Write-Host " Checking cluster '$CLUSTER_NAME'..." -ForegroundColor Yellow
$existingClusters = @()
try {
    $existingClusters = kind get clusters 2>$null
} catch {
    $existingClusters = @()
}
if ($existingClusters -match $CLUSTER_NAME) {
    Write-Host " kind cluster '$CLUSTER_NAME' already exists" -ForegroundColor Green
} else {
    Write-Host "Creating kind cluster '$CLUSTER_NAME'" -ForegroundColor Yellow
    $clusterConfig = Join-Path $K8S_DIR "kind-cluster.yaml"
    kind create cluster --name $CLUSTER_NAME --config $clusterConfig
    if ($LASTEXITCODE -ne 0) {
        Write-Host " Failed to create cluster" -ForegroundColor Red
        exit 1
    }
    Write-Host " Cluster created successfully" -ForegroundColor Green
}
Write-Host ""

# Set kubectl context
Write-Host " Setting kubectl context..." -ForegroundColor Yellow
kubectl config use-context "kind-$CLUSTER_NAME" | Out-Null
Write-Host " Context set to kind-$CLUSTER_NAME" -ForegroundColor Green
Write-Host ""

# Wait until Kubernetes API is reachable
Write-Host " Waiting for Kubernetes API server..." -ForegroundColor Yellow
$apiReady = $false
for ($i = 1; $i -le 30; $i++) {
    try {
        kubectl cluster-info --request-timeout=5s *> $null
        if ($LASTEXITCODE -eq 0) {
            $apiReady = $true
            break
        }
    } catch {
        # API may not be reachable yet while control-plane is starting.
    }
    Start-Sleep -Seconds 2
}

if (-not $apiReady) {
    Write-Host " Kubernetes API did not become reachable in time" -ForegroundColor Red
    Write-Host " Try: docker ps --filter name=feastflow-local-control-plane" -ForegroundColor Yellow
    exit 1
}

Write-Host " Kubernetes API is reachable" -ForegroundColor Green
Write-Host ""

# Build backend image
Write-Host " Building backend image..." -ForegroundColor Yellow
docker build -t feastflow-backend:latest $BACKEND_DIR
if ($LASTEXITCODE -ne 0) {
    Write-Host " Failed to build backend image" -ForegroundColor Red
    exit 1
}
Write-Host "Backend image built" -ForegroundColor Green
Write-Host ""

# Build frontend image
Write-Host " Building frontend image..." -ForegroundColor Yellow
docker build -t feastflow-frontend:latest $FRONTEND_DIR
if ($LASTEXITCODE -ne 0) {
    Write-Host " Failed to build frontend image" -ForegroundColor Red
    exit 1
}
Write-Host " Frontend image built" -ForegroundColor Green
Write-Host ""

# Load images into kind
Write-Host " Loading images into kind cluster..." -ForegroundColor Yellow
kind load docker-image feastflow-backend:latest --name $CLUSTER_NAME
kind load docker-image feastflow-frontend:latest --name $CLUSTER_NAME
Write-Host " Images loaded into cluster" -ForegroundColor Green
Write-Host ""

# Apply Kubernetes manifests
Write-Host " Applying Kubernetes manifests..." -ForegroundColor Yellow
$manifests = @(
    "00-namespace.yaml",
    "01-configmap.yaml",
    "02-secrets.yaml",
    "03-postgres-pvc.yaml",
    "04-postgres-deployment.yaml",
    "05-postgres-service.yaml",
    "06-backend-deployment.yaml",
    "07-backend-service.yaml",
    "08-frontend-deployment.yaml",
    "09-frontend-service.yaml",
    "10-ingress.yaml"
)

foreach ($manifest in $manifests) {
    $manifestPath = Join-Path $K8S_DIR $manifest
    Write-Host "  Applying $manifest..." -ForegroundColor Gray
    kubectl apply -f $manifestPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host " Failed to apply $manifest" -ForegroundColor Red
        exit 1
    }
}
Write-Host " All manifests applied" -ForegroundColor Green
Write-Host ""

# Wait for rollouts
Write-Host " Waiting for deployments to be ready..." -ForegroundColor Yellow
Write-Host "  Waiting for PostgreSQL..." -ForegroundColor Gray
kubectl rollout status statefulset/postgres -n feastflow --timeout=180s

Write-Host "  Waiting for backend..." -ForegroundColor Gray
kubectl rollout status deployment/feastflow-backend -n feastflow --timeout=180s

Write-Host "  Waiting for frontend..." -ForegroundColor Gray
kubectl rollout status deployment/feastflow-frontend -n feastflow --timeout=180s

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host " FeastFlow Kubernetes cluster is ready!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host " Verification Commands:" -ForegroundColor Cyan
Write-Host "  kubectl config current-context" -ForegroundColor White
Write-Host "  kubectl cluster-info" -ForegroundColor White
Write-Host "  kubectl get nodes" -ForegroundColor White
Write-Host "  kubectl get pods -n feastflow" -ForegroundColor White
Write-Host "  kubectl get services -n feastflow" -ForegroundColor White
Write-Host ""
Write-Host " Access Application:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n feastflow service/feastflow-frontend 3000:3000" -ForegroundColor White
Write-Host "  Then open: http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host " View Logs:" -ForegroundColor Cyan
Write-Host "  kubectl logs -f -n feastflow deployment/feastflow-backend" -ForegroundColor White
Write-Host "  kubectl logs -f -n feastflow deployment/feastflow-frontend" -ForegroundColor White
Write-Host ""
