# FeastFlow Ingress Verification Script (PowerShell)
# Verifies nginx ingress controller availability and HTTP routing to frontend/backend

[CmdletBinding()]
param(
    [string]$HostName = "feastflow.local",
    [string]$BaseUrl = "http://localhost"
)

$ErrorActionPreference = "Stop"

Write-Host "=== FeastFlow Ingress Verification ===" -ForegroundColor Cyan

if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "kubectl is required but not installed." -ForegroundColor Red
    exit 1
}

if (!(Get-Command curl.exe -ErrorAction SilentlyContinue)) {
    Write-Host "curl.exe is required but not available in PATH." -ForegroundColor Red
    exit 1
}

Write-Host "[1/5] Checking ingress-nginx controller..." -ForegroundColor Yellow
kubectl get deployment ingress-nginx-controller -n ingress-nginx *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ingress-nginx controller deployment not found. Run setup-kind.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "[2/5] Checking FeastFlow ingress resource..." -ForegroundColor Yellow
kubectl get ingress feastflow-ingress -n feastflow *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Ingress resource feastflow-ingress not found in namespace feastflow." -ForegroundColor Red
    exit 1
}

Write-Host "[3/5] Showing ingress summary" -ForegroundColor Yellow
kubectl get ingress feastflow-ingress -n feastflow

Write-Host "[4/5] Testing frontend route '/'..." -ForegroundColor Yellow
$frontendStatus = curl.exe -s -o NUL -w "%{http_code}" -H "Host: $HostName" "$BaseUrl/"
if ($frontendStatus -lt 200 -or $frontendStatus -ge 400) {
    Write-Host "Frontend route failed (status: $frontendStatus)" -ForegroundColor Red
    exit 1
}
Write-Host "Frontend route reachable (status: $frontendStatus)" -ForegroundColor Green

Write-Host "[5/5] Testing backend route '/api/health'..." -ForegroundColor Yellow
$backendStatus = curl.exe -s -o NUL -w "%{http_code}" -H "Host: $HostName" "$BaseUrl/api/health"
if ($backendStatus -lt 200 -or $backendStatus -ge 400) {
    Write-Host "Backend route failed (status: $backendStatus)" -ForegroundColor Red
    exit 1
}

Write-Host "Backend route reachable (status: $backendStatus)" -ForegroundColor Green
Write-Host ""
Write-Host "Ingress routing is working:" -ForegroundColor Cyan
Write-Host "  $BaseUrl/             -> feastflow-frontend service" -ForegroundColor White
Write-Host "  $BaseUrl/api/health   -> feastflow-backend service" -ForegroundColor White
Write-Host ""
Write-Host "Tip: Add hosts entry '127.0.0.1 $HostName' to use http://$HostName directly." -ForegroundColor Gray
