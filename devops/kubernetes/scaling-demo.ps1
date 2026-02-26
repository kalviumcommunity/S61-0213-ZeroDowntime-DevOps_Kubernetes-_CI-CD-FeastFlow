# Manual Scaling Demo Script for FeastFlow
# Demonstrates manual replica scaling in Kubernetes
# Author: DevOps Team
# Purpose: Show manual control over deployment replicas

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  FeastFlow Manual Scaling Demonstration" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Function to display current status
function Show-DeploymentStatus {
    param([string]$DeploymentName)
    
    Write-Host "`nCurrent Status of $DeploymentName:" -ForegroundColor Yellow
    kubectl get deployment $DeploymentName -n feastflow -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,AVAILABLE:.status.availableReplicas,DESIRED:.spec.replicas
    kubectl get pods -n feastflow -l component=backend --no-headers | Measure-Object | ForEach-Object { Write-Host "Total Pods: $($_.Count)" -ForegroundColor Green }
}

# Function to wait for rollout
function Wait-ForRollout {
    param([string]$DeploymentName)
    
    Write-Host "`nWaiting for rollout to complete..." -ForegroundColor Yellow
    kubectl rollout status deployment/$DeploymentName -n feastflow --timeout=120s
}

# Check if namespace exists
Write-Host "[Step 1] Verifying namespace..." -ForegroundColor Green
$namespaceExists = kubectl get namespace feastflow 2>$null
if (-not $namespaceExists) {
    Write-Host "ERROR: Namespace 'feastflow' not found. Please run setup first." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Namespace exists" -ForegroundColor Green

# Show initial state
Write-Host "`n[Step 2] Initial Deployment State" -ForegroundColor Green
Show-DeploymentStatus "feastflow-backend"

# Scale up demonstration
Write-Host "`n[Step 3] Scaling UP from 2 to 5 replicas" -ForegroundColor Green
Write-Host "Command: kubectl scale deployment feastflow-backend --replicas=5 -n feastflow" -ForegroundColor Gray
kubectl scale deployment feastflow-backend --replicas=5 -n feastflow

Write-Host "`nWatching pods as they come online..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
kubectl get pods -n feastflow -l component=backend -w --timeout=30s

Show-DeploymentStatus "feastflow-backend"

# Demonstrate immediate availability
Write-Host "`n[Step 4] Verifying Service Load Distribution" -ForegroundColor Green
Write-Host "Checking endpoints registered with service..." -ForegroundColor Yellow
kubectl get endpoints feastflow-backend -n feastflow

# Scale down demonstration
Write-Host "`n[Step 5] Scaling DOWN from 5 to 3 replicas" -ForegroundColor Green
Write-Host "This demonstrates cost optimization during low-traffic periods" -ForegroundColor Gray
kubectl scale deployment feastflow-backend --replicas=3 -n feastflow

Wait-ForRollout "feastflow-backend"
Show-DeploymentStatus "feastflow-backend"

# Alternative methods demonstration
Write-Host "`n[Step 6] Alternative Scaling Methods" -ForegroundColor Green
Write-Host "Method 1 - Using kubectl scale (just demonstrated)" -ForegroundColor Cyan
Write-Host "  kubectl scale deployment feastflow-backend --replicas=N -n feastflow" -ForegroundColor Gray

Write-Host "`nMethod 2 - Using kubectl patch" -ForegroundColor Cyan
Write-Host "  kubectl patch deployment feastflow-backend -n feastflow -p '{""spec"":{""replicas"":4}}'" -ForegroundColor Gray

Write-Host "`nMethod 3 - Using kubectl edit (interactive)" -ForegroundColor Cyan
Write-Host "  kubectl edit deployment feastflow-backend -n feastflow" -ForegroundColor Gray

Write-Host "`nMethod 4 - Updating YAML file and applying" -ForegroundColor Cyan
Write-Host "  kubectl apply -f 06-backend-deployment.yaml" -ForegroundColor Gray

# Show ReplicaSet history
Write-Host "`n[Step 7] ReplicaSet Management" -ForegroundColor Green
Write-Host "Kubernetes uses ReplicaSets to manage pod replicas:" -ForegroundColor Yellow
kubectl get replicasets -n feastflow -l component=backend

# Restore original state
Write-Host "`n[Step 8] Restoring Original Configuration (2 replicas)" -ForegroundColor Green
kubectl scale deployment feastflow-backend --replicas=2 -n feastflow
Wait-ForRollout "feastflow-backend"
Show-DeploymentStatus "feastflow-backend"

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  Manual Scaling Demo Complete!" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "`nKey Takeaways:" -ForegroundColor Yellow
Write-Host "✓ Manual scaling is instant and seamless" -ForegroundColor Green
Write-Host "✓ No downtime during scaling operations" -ForegroundColor Green
Write-Host "✓ Service automatically load-balances across all replicas" -ForegroundColor Green
Write-Host "✓ Scaling can be done through multiple methods" -ForegroundColor Green
Write-Host "`nNext: Try HPA for automatic scaling based on metrics!" -ForegroundColor Cyan
Write-Host "Run: kubectl apply -f 12-backend-hpa.yaml" -ForegroundColor Gray
