# HPA Load Test and Verification Script
# Generates load on backend to trigger HPA scaling
# Monitors scaling behavior in real-time

param(
    [Parameter(Mandatory=$false)]
    [int]$Duration = 180,  # Duration in seconds (default 3 minutes)
    
    [Parameter(Mandatory=$false)]
    [int]$Concurrent = 10,  # Number of concurrent requests
    
    [Parameter(Mandatory=$false)]
    [string]$Target = "backend"  # Target deployment: backend or frontend
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  FeastFlow HPA Load Test & Verification" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Verify prerequisites
Write-Host "[Pre-check] Verifying prerequisites..." -ForegroundColor Green

# Check if metrics-server is available
Write-Host "Checking metrics-server..." -ForegroundColor Yellow
$metricsServer = kubectl get deployment metrics-server -n kube-system 2>$null
if (-not $metricsServer) {
    Write-Host "WARNING: metrics-server not found. Installing..." -ForegroundColor Yellow
    Write-Host "Command: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml" -ForegroundColor Gray
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    Write-Host "Waiting 30s for metrics-server to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
}

# For KIND clusters, patch metrics-server to disable TLS verification
Write-Host "Patching metrics-server for KIND cluster..." -ForegroundColor Yellow
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' 2>$null

Write-Host "✓ Prerequisites checked" -ForegroundColor Green

# Verify HPA exists
Write-Host "`n[Step 1] Verifying HPA configuration..." -ForegroundColor Green
$hpaName = "feastflow-$Target-hpa"
$hpaExists = kubectl get hpa $hpaName -n feastflow 2>$null
if (-not $hpaExists) {
    Write-Host "ERROR: HPA '$hpaName' not found. Applying configuration..." -ForegroundColor Red
    kubectl apply -f devops/kubernetes/12-backend-hpa.yaml
    Start-Sleep -Seconds 10
}

Write-Host "`nCurrent HPA Status:" -ForegroundColor Yellow
kubectl get hpa $hpaName -n feastflow

# Show initial deployment state
Write-Host "`n[Step 2] Initial State" -ForegroundColor Green
$deploymentName = "feastflow-$Target"
kubectl get deployment $deploymentName -n feastflow
kubectl top pods -n feastflow -l component=$Target 2>$null

# Get service endpoint
Write-Host "`n[Step 3] Preparing Load Test" -ForegroundColor Green
$serviceIP = kubectl get svc $deploymentName -n feastflow -o jsonpath='{.spec.clusterIP}'
$servicePort = kubectl get svc $deploymentName -n feastflow -o jsonpath='{.spec.ports[0].port}'
$endpoint = "http://${serviceIP}:${servicePort}/api/health"

Write-Host "Target Endpoint: $endpoint" -ForegroundColor Cyan
Write-Host "Duration: $Duration seconds" -ForegroundColor Cyan
Write-Host "Concurrent Requests: $Concurrent" -ForegroundColor Cyan

# Start load test in background
Write-Host "`n[Step 4] Starting Load Test..." -ForegroundColor Green
Write-Host "Generating CPU load to trigger HPA..." -ForegroundColor Yellow

$loadTestScript = @"
`$endpoint = '$endpoint'
`$duration = $Duration
`$endTime = (Get-Date).AddSeconds(`$duration)

while ((Get-Date) -lt `$endTime) {
    try {
        1..$Concurrent | ForEach-Object -Parallel {
            for (`$i = 0; `$i -lt 100; `$i++) {
                Invoke-WebRequest -Uri `$using:endpoint -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue | Out-Null
            }
        } -ThrottleLimit $Concurrent
    } catch {}
}
"@

# Start load generator
$loadJob = Start-Job -ScriptBlock ([ScriptBlock]::Create($loadTestScript))

Write-Host "Load test started (Job ID: $($loadJob.Id))" -ForegroundColor Green
Write-Host "`nMonitoring HPA scaling behavior..." -ForegroundColor Yellow
Write-Host "(Press Ctrl+C to stop monitoring, load test will continue)" -ForegroundColor Gray
Write-Host ""

# Monitor loop
$startTime = Get-Date
$iteration = 0
try {
    while ((Get-Date) -lt $startTime.AddSeconds($Duration + 30)) {
        $iteration++
        $elapsed = [int]((Get-Date) - $startTime).TotalSeconds
        
        Write-Host "--- Iteration $iteration (${elapsed}s elapsed) ---" -ForegroundColor Cyan
        
        # Show HPA status
        Write-Host "`nHPA Status:" -ForegroundColor Yellow
        kubectl get hpa $hpaName -n feastflow
        
        # Show pod metrics
        Write-Host "`nPod Metrics:" -ForegroundColor Yellow
        kubectl top pods -n feastflow -l component=$Target 2>$null
        
        # Show deployment replicas
        Write-Host "`nDeployment Status:" -ForegroundColor Yellow
        kubectl get deployment $deploymentName -n feastflow -o custom-columns=NAME:.metadata.name,DESIRED:.spec.replicas,CURRENT:.status.replicas,READY:.status.readyReplicas,UP-TO-DATE:.status.updatedReplicas
        
        # Show pod list
        Write-Host "`nPods:" -ForegroundColor Yellow
        kubectl get pods -n feastflow -l component=$Target -o wide
        
        Write-Host "`n" ("-" * 60) -ForegroundColor Gray
        Start-Sleep -Seconds 15
    }
} catch {
    Write-Host "`nMonitoring stopped by user." -ForegroundColor Yellow
}

# Wait for load test to complete
Write-Host "`nWaiting for load test to complete..." -ForegroundColor Yellow
Wait-Job -Job $loadJob -Timeout 30 | Out-Null
Remove-Job -Job $loadJob -Force

# Final status
Write-Host "`n[Step 5] Final Status" -ForegroundColor Green
Write-Host "`nFinal HPA Status:" -ForegroundColor Yellow
kubectl get hpa $hpaName -n feastflow

Write-Host "`nFinal Deployment Status:" -ForegroundColor Yellow
kubectl get deployment $deploymentName -n feastflow

Write-Host "`nFinal Pod Metrics:" -ForegroundColor Yellow
kubectl top pods -n feastflow -l component=$Target 2>$null

# Show scaling events
Write-Host "`n[Step 6] Scaling Events" -ForegroundColor Green
Write-Host "Recent HPA scaling events:" -ForegroundColor Yellow
kubectl describe hpa $hpaName -n feastflow | Select-String -Pattern "Events:" -Context 0,20

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  Load Test Complete!" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "`nObservations:" -ForegroundColor Yellow
Write-Host "✓ Check if replicas increased during load" -ForegroundColor Green
Write-Host "✓ Note the scaling threshold that triggered autoscaling" -ForegroundColor Green
Write-Host "✓ Observe scale-down behavior after load stops" -ForegroundColor Green
Write-Host "`nNote: Scale-down is gradual (5-min stabilization window)" -ForegroundColor Cyan
Write-Host "Monitor with: kubectl get hpa $hpaName -n feastflow --watch" -ForegroundColor Gray
