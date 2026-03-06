#!/usr/bin/env pwsh
# deploy-logging.ps1
# Deploys the complete centralized logging stack (Loki + Fluent Bit + Grafana)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FeastFlow Centralized Logging Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Write-Success { param($msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "ℹ $msg" -ForegroundColor Yellow }
function Write-Section { param($msg) Write-Host "`n--- $msg ---" -ForegroundColor Cyan }

# Check if namespace exists
Write-Section "Checking Prerequisites"

$namespace = kubectl get namespace feastflow -o json 2>$null | ConvertFrom-Json
if (-not $namespace) {
    Write-Info "Creating feastflow namespace..."
    kubectl apply -f 00-namespace.yaml
    Write-Success "Namespace created"
} else {
    Write-Success "Namespace exists"
}

# Deploy logging components
Write-Section "Deploying Logging Stack"

Write-Info "Deploying Loki (log storage and indexing)..."
kubectl apply -f 15-loki.yaml
if ($LASTEXITCODE -eq 0) {
    Write-Success "Loki deployed"
} else {
    Write-Host "✗ Failed to deploy Loki" -ForegroundColor Red
    exit 1
}

Write-Info "Deploying Fluent Bit (log collector)..."
kubectl apply -f 16-fluent-bit.yaml
if ($LASTEXITCODE -eq 0) {
    Write-Success "Fluent Bit deployed"
} else {
    Write-Host "✗ Failed to deploy Fluent Bit" -ForegroundColor Red
    exit 1
}

Write-Info "Deploying Grafana (log visualization)..."
kubectl apply -f 17-grafana.yaml
if ($LASTEXITCODE -eq 0) {
    Write-Success "Grafana deployed"
} else {
    Write-Host "✗ Failed to deploy Grafana" -ForegroundColor Red
    exit 1
}

# Wait for deployments to be ready
Write-Section "Waiting for Components to be Ready"

Write-Info "Waiting for Loki to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/loki -n feastflow
if ($LASTEXITCODE -eq 0) {
    Write-Success "Loki is ready"
} else {
    Write-Host "✗ Loki did not become ready in time" -ForegroundColor Red
}

Write-Info "Waiting for Fluent Bit to be ready..."
Start-Sleep -Seconds 10
$fluentBitReady = kubectl get daemonset fluent-bit -n feastflow -o jsonpath='{.status.numberReady}' 2>$null
$fluentBitDesired = kubectl get daemonset fluent-bit -n feastflow -o jsonpath='{.status.desiredNumberScheduled}' 2>$null
if ($fluentBitReady -eq $fluentBitDesired) {
    Write-Success "Fluent Bit is ready ($fluentBitReady/$fluentBitDesired pods)"
} else {
    Write-Info "Fluent Bit: $fluentBitReady/$fluentBitDesired pods ready (may take a moment)"
}

Write-Info "Waiting for Grafana to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/grafana -n feastflow
if ($LASTEXITCODE -eq 0) {
    Write-Success "Grafana is ready"
} else {
    Write-Host "✗ Grafana did not become ready in time" -ForegroundColor Red
}

# Get Grafana URL
Write-Section "Access Information"

$grafanaPort = kubectl get service grafana -n feastflow -o jsonpath='{.spec.ports[0].nodePort}' 2>$null
if ($grafanaPort) {
    Write-Host ""
    Write-Host "Centralized Logging Stack Deployed Successfully! 🎉" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access Grafana:" -ForegroundColor Cyan
    Write-Host "  URL:      http://localhost:$grafanaPort" -ForegroundColor White
    Write-Host "  Username: admin" -ForegroundColor White
    Write-Host "  Password: feastflow2024" -ForegroundColor White
    Write-Host ""
    Write-Host "Quick Start:" -ForegroundColor Cyan
    Write-Host "  1. Open http://localhost:$grafanaPort in your browser" -ForegroundColor White
    Write-Host "  2. Login with admin/feastflow2024" -ForegroundColor White
    Write-Host "  3. Go to Explore (compass icon)" -ForegroundColor White
    Write-Host "  4. Select 'Loki' datasource" -ForegroundColor White
    Write-Host "  5. Try query: {k8s_namespace_name=`"feastflow`"}" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Verify Installation:" -ForegroundColor Cyan
    Write-Host "  .\verify-centralized-logging.ps1" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Documentation:" -ForegroundColor Cyan
    Write-Host "  See CENTRALIZED_LOGGING.md for detailed usage guide" -ForegroundColor White
    Write-Host ""
}

# Show deployed resources
Write-Section "Deployed Resources"

Write-Host ""
Write-Host "Pods:" -ForegroundColor Cyan
kubectl get pods -n feastflow -l component=logging

Write-Host "`nServices:" -ForegroundColor Cyan
kubectl get svc -n feastflow -l component=logging

Write-Host "`nPersistentVolumeClaims:" -ForegroundColor Cyan
kubectl get pvc -n feastflow | Select-String "loki|grafana"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
