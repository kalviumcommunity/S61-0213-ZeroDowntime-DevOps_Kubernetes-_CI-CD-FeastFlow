Param(
    [string]$Namespace = "feastflow"
)

$ErrorActionPreference = "Stop"
$namespaceManifest = Join-Path $PSScriptRoot "00-namespace.yaml"
$persistenceManifest = Join-Path $PSScriptRoot "13-persistence-demo.yaml"

Write-Host "============================================================"
Write-Host "FeastFlow Kubernetes Persistent Volume Verification"
Write-Host "Namespace: $Namespace"
Write-Host "============================================================"

Write-Host "[1/7] Checking cluster connectivity"
kubectl cluster-info | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Cannot connect to Kubernetes cluster. Ensure your cluster is running and kubectl context is valid."
}

Write-Host "[2/7] Applying namespace and persistence demo manifest"
kubectl apply -f $namespaceManifest | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Failed to apply 00-namespace.yaml"
}
kubectl apply -f $persistenceManifest | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Failed to apply 13-persistence-demo.yaml"
}

Write-Host "[3/7] Waiting for PVC to bind"
Write-Host "   Ensuring persistence demo pod is created..."
$podCreated = $false
for ($i = 1; $i -le 60; $i++) {
    $podNameProbe = kubectl get pods -n $Namespace -l component=persistence-demo -o jsonpath='{.items[0].metadata.name}' 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($podNameProbe)) {
        $podCreated = $true
        break
    }
    Start-Sleep -Seconds 2
}
if (-not $podCreated) {
    Write-Host "Pod was not created in time. Diagnostics:" -ForegroundColor Yellow
    kubectl get deployment feastflow-persistence-demo -n $Namespace -o wide
    kubectl get pods -n $Namespace -l component=persistence-demo -o wide
    kubectl get events -n $Namespace --sort-by=.lastTimestamp | Select-Object -Last 20
    throw "Persistence demo pod was not created"
}

Write-Host "   Waiting for pod scheduling (required by WaitForFirstConsumer)..."
$podScheduled = $false
for ($i = 1; $i -le 90; $i++) {
    $scheduledNode = kubectl get pods -n $Namespace -l component=persistence-demo -o jsonpath='{.items[0].spec.nodeName}' 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($scheduledNode)) {
        $podScheduled = $true
        break
    }
    Start-Sleep -Seconds 2
}
if (-not $podScheduled) {
    Write-Host "Pod was not scheduled in time. Diagnostics:" -ForegroundColor Yellow
    kubectl get nodes -o wide
    kubectl get pods -n $Namespace -l component=persistence-demo -o wide
    $podName = kubectl get pods -n $Namespace -l component=persistence-demo -o jsonpath='{.items[0].metadata.name}' 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($podName)) {
        kubectl describe pod $podName -n $Namespace
    }
    kubectl get events -n $Namespace --sort-by=.lastTimestamp | Select-Object -Last 20
    throw "Persistence demo pod was not scheduled"
}

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/persistence-demo-pvc -n $Namespace --timeout=300s | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "PVC did not bind in time. Diagnostics:" -ForegroundColor Yellow
    kubectl get pvc persistence-demo-pvc -n $Namespace -o wide
    kubectl describe pvc persistence-demo-pvc -n $Namespace
    throw "PVC persistence-demo-pvc did not reach Bound state"
}
$pvcStatus = kubectl get pvc persistence-demo-pvc -n $Namespace -o jsonpath='{.status.phase}'
if ($LASTEXITCODE -ne 0) {
    throw "Failed to read PVC status for persistence-demo-pvc"
}
Write-Host "PVC status: $pvcStatus"

Write-Host "[4/7] Waiting for demo pod readiness"
kubectl rollout status deployment/feastflow-persistence-demo -n $Namespace --timeout=180s | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Deployment feastflow-persistence-demo did not become ready"
}
kubectl wait --for=condition=Ready pod -l component=persistence-demo -n $Namespace --timeout=180s | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "No ready persistence demo pod available"
}
$oldPod = kubectl get pods -n $Namespace -l component=persistence-demo --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}'
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($oldPod)) {
    throw "Failed to resolve running persistence demo pod"
}
Write-Host "Current pod: $oldPod"

Write-Host "[5/7] Writing marker data to mounted volume"
$marker = "persist-proof-$(Get-Date -Format 'yyyyMMddHHmmss')"
kubectl exec -n $Namespace $oldPod -- sh -c "echo '$marker' > /data/proof.txt; sync"
if ($LASTEXITCODE -ne 0) {
    throw "Failed to write marker to /data/proof.txt"
}
$written = (kubectl exec -n $Namespace $oldPod -- cat /data/proof.txt).Trim()
if ($LASTEXITCODE -ne 0) {
    throw "Failed to read marker after write from /data/proof.txt"
}
Write-Host "Marker written: $written"
if ($written -ne $marker) {
    throw "Write verification failed: expected '$marker' but got '$written'"
}

Write-Host "[6/7] Deleting pod to simulate restart"
kubectl delete pod $oldPod -n $Namespace --wait=false | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Failed to delete pod $oldPod"
}
kubectl wait --for=delete pod/$oldPod -n $Namespace --timeout=180s | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Pod $oldPod did not terminate in time"
}
kubectl rollout status deployment/feastflow-persistence-demo -n $Namespace --timeout=180s | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Deployment feastflow-persistence-demo did not recover after pod deletion"
}
kubectl wait --for=condition=Ready pod -l component=persistence-demo -n $Namespace --timeout=180s | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "No ready persistence demo pod available after restart"
}
$newPod = kubectl get pods -n $Namespace -l component=persistence-demo --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}'
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($newPod) -or $newPod -eq $oldPod) {
    $newPod = kubectl get pods -n $Namespace -l component=persistence-demo --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | Where-Object { $_ -and $_ -ne $oldPod } | Select-Object -First 1
}
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($newPod)) {
    throw "Failed to resolve replacement persistence demo pod"
}
Write-Host "New pod: $newPod"

Write-Host "[7/7] Reading marker after restart"
$afterRestart = (kubectl exec -n $Namespace $newPod -- cat /data/proof.txt).Trim()
if ($LASTEXITCODE -ne 0) {
    throw "Failed to read marker after pod restart from /data/proof.txt"
}
Write-Host "Marker after restart: $afterRestart"

if ($afterRestart -ne $marker) {
    throw "Persistence check failed: expected '$marker' but got '$afterRestart'"
}

Write-Host ""
Write-Host "✅ Persistence verified: data survived pod restart using PVC."
Write-Host "   PVC: persistence-demo-pvc"
Write-Host "   Pod replaced: $oldPod -> $newPod"
