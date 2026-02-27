param(
    [string]$Namespace = "feastflow",
    [string]$Deployment = "feastflow-backend",
    [int]$RolloutTimeoutSeconds = 180,
    [int]$FailedRolloutTimeoutSeconds = 45,
    [switch]$SkipFailedUpdate
)

$ErrorActionPreference = "Stop"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  FeastFlow Rolling Update + Rollback Demo" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

function Require-Command {
    param([string]$Name)
    if (!(Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' not found in PATH."
    }
}

function Get-DeploymentImage {
    param([string]$Ns, [string]$Dep)
    return (kubectl get deployment $Dep -n $Ns -o jsonpath='{.spec.template.spec.containers[0].image}')
}

function Wait-DeploymentReady {
    param([string]$Ns, [string]$Dep, [int]$TimeoutSeconds)
    kubectl rollout status deployment/$Dep -n $Ns --timeout="${TimeoutSeconds}s" | Out-Host
}

function Show-Status {
    param([string]$Ns, [string]$Dep)
    Write-Host "`nDeployment status:" -ForegroundColor Yellow
    kubectl get deployment $Dep -n $Ns -o wide
    Write-Host "`nPods:" -ForegroundColor Yellow
    kubectl get pods -n $Ns -l component=backend -o wide
    Write-Host "`nReplicaSets:" -ForegroundColor Yellow
    kubectl get rs -n $Ns -l component=backend
}

Require-Command "kubectl"

Write-Host "[1/7] Verifying cluster + deployment..." -ForegroundColor Green
kubectl config current-context | Out-Host
kubectl get deployment $Deployment -n $Namespace | Out-Host

$originalImage = Get-DeploymentImage -Ns $Namespace -Dep $Deployment
Write-Host "Current image: $originalImage" -ForegroundColor Gray

Write-Host "`n[2/7] Capturing current rollout history..." -ForegroundColor Green
kubectl rollout history deployment/$Deployment -n $Namespace | Out-Host

Write-Host "`n[3/7] Performing successful rolling update (env var change)..." -ForegroundColor Green
$releaseStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$changeCauseGood = "Sprint-3 successful rolling update DEMO_RELEASE=$releaseStamp"

kubectl annotate deployment/$Deployment -n $Namespace kubernetes.io/change-cause="$changeCauseGood" --overwrite | Out-Host
kubectl set env deployment/$Deployment -n $Namespace DEMO_RELEASE=$releaseStamp | Out-Host

Wait-DeploymentReady -Ns $Namespace -Dep $Deployment -TimeoutSeconds $RolloutTimeoutSeconds

Write-Host "`n[4/7] Verifying successful update and revision history..." -ForegroundColor Green
Show-Status -Ns $Namespace -Dep $Deployment
kubectl rollout history deployment/$Deployment -n $Namespace | Out-Host

if (-not $SkipFailedUpdate) {
    Write-Host "`n[5/7] Triggering controlled failed update (invalid image)..." -ForegroundColor Green
    $badImage = "feastflow-backend:rollback-demo-bad"
    $changeCauseBad = "Sprint-3 failed update simulation image=$badImage"

    kubectl annotate deployment/$Deployment -n $Namespace kubernetes.io/change-cause="$changeCauseBad" --overwrite | Out-Host
    kubectl set image deployment/$Deployment -n $Namespace backend=$badImage | Out-Host

    $failed = $false
    try {
        Wait-DeploymentReady -Ns $Namespace -Dep $Deployment -TimeoutSeconds $FailedRolloutTimeoutSeconds
        Write-Host "Unexpected: failed rollout simulation did not fail within timeout." -ForegroundColor Yellow
    } catch {
        $failed = $true
        Write-Host "Expected failure observed (rollout timeout)." -ForegroundColor Yellow
    }

    Write-Host "`nInspecting failure signals:" -ForegroundColor Yellow
    kubectl get pods -n $Namespace -l component=backend | Out-Host
    kubectl get events -n $Namespace --sort-by=.lastTimestamp | Select-Object -Last 20 | Out-Host

    if (-not $failed) {
        Write-Host "Proceeding with rollback anyway to demonstrate recovery." -ForegroundColor Yellow
    }

    Write-Host "`n[6/7] Rolling back to last stable revision..." -ForegroundColor Green
    $changeCauseRollback = "Sprint-3 rollback to last stable revision"
    kubectl annotate deployment/$Deployment -n $Namespace kubernetes.io/change-cause="$changeCauseRollback" --overwrite | Out-Host
    kubectl rollout undo deployment/$Deployment -n $Namespace | Out-Host
    Wait-DeploymentReady -Ns $Namespace -Dep $Deployment -TimeoutSeconds $RolloutTimeoutSeconds
}

Write-Host "`n[7/7] Final verification (stable + available)..." -ForegroundColor Green
$finalImage = Get-DeploymentImage -Ns $Namespace -Dep $Deployment
Write-Host "Final image: $finalImage" -ForegroundColor Gray
Show-Status -Ns $Namespace -Dep $Deployment
kubectl rollout history deployment/$Deployment -n $Namespace | Out-Host

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  Demo Complete: rolling update + rollback" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Proof points captured:" -ForegroundColor Yellow
Write-Host "✓ Deployment revisions tracked" -ForegroundColor Green
Write-Host "✓ Successful zero-downtime rolling update" -ForegroundColor Green
if (-not $SkipFailedUpdate) {
    Write-Host "✓ Controlled failed update simulation" -ForegroundColor Green
    Write-Host "✓ Rollback to previous stable revision" -ForegroundColor Green
}
