Param(
    [string]$Namespace = "feastflow"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================================"
Write-Host "FeastFlow Kubernetes Resource Management Verification"
Write-Host "Namespace: $Namespace"
Write-Host "============================================================"

Write-Host "[1/6] Checking cluster connectivity"
kubectl cluster-info | Out-Null

Write-Host "[2/6] Applying namespace, config, storage, and workloads"
kubectl apply -f "devops/kubernetes/00-namespace.yaml" | Out-Null
kubectl apply -f "devops/kubernetes/01-configmap.yaml" | Out-Null
kubectl apply -f "devops/kubernetes/02-secrets.yaml" | Out-Null
kubectl apply -f "devops/kubernetes/03-postgres-pvc.yaml" | Out-Null
kubectl apply -f "devops/kubernetes/04-postgres-deployment.yaml" | Out-Null
kubectl apply -f "devops/kubernetes/06-backend-deployment.yaml" | Out-Null
kubectl apply -f "devops/kubernetes/08-frontend-deployment.yaml" | Out-Null

Write-Host "[3/6] Verifying requests/limits are defined on workload specs"
$workloads = @(
    "statefulset/postgres",
    "deployment/feastflow-backend",
    "deployment/feastflow-frontend"
)

foreach ($workload in $workloads) {
    $requests = kubectl get $workload -n $Namespace -o jsonpath='{.spec.template.spec.containers[0].resources.requests}'
    $limits = kubectl get $workload -n $Namespace -o jsonpath='{.spec.template.spec.containers[0].resources.limits}'
    Write-Host "$workload -> requests=$requests limits=$limits"

    if ([string]::IsNullOrWhiteSpace($requests) -or [string]::IsNullOrWhiteSpace($limits) -or $requests -eq "map[]" -or $limits -eq "map[]") {
        throw "Missing requests/limits on $workload"
    }
}

Write-Host "[4/6] Verifying pods are scheduled (scheduler used requests)"
$selectors = @("component=database", "component=backend", "component=frontend")
foreach ($selector in $selectors) {
    Write-Host ""
    Write-Host "--- $selector ---"
    kubectl wait --for=condition=PodScheduled pod -l $selector -n $Namespace --timeout=120s | Out-Null
    $pod = kubectl get pods -n $Namespace -l $selector -o jsonpath='{.items[0].metadata.name}'
    Write-Host "Scheduled pod: $pod"
}

Write-Host "[5/6] Verifying stability (pods running within limits)"
kubectl rollout status statefulset/postgres -n $Namespace --timeout=180s
$postgresOk = $LASTEXITCODE -eq 0

kubectl rollout status deployment/feastflow-backend -n $Namespace --timeout=180s
$backendOk = $LASTEXITCODE -eq 0

kubectl rollout status deployment/feastflow-frontend -n $Namespace --timeout=180s
$frontendOk = $LASTEXITCODE -eq 0

kubectl get pods -n $Namespace -o wide

if (-not ($postgresOk -and $backendOk -and $frontendOk)) {
    Write-Host ""
    Write-Host "One or more workloads are not stable yet. Collecting concise failure reasons..."
    foreach ($selector in @("component=backend", "component=frontend")) {
        $pod = kubectl get pods -n $Namespace -l $selector -o jsonpath='{.items[0].metadata.name}'
        Write-Host ""
        Write-Host "$selector pod: $pod"
        kubectl get pod $pod -n $Namespace -o custom-columns=PHASE:.status.phase,WAITING_REASON:.status.containerStatuses[0].state.waiting.reason --no-headers
    }

    Write-Host ""
    Write-Host "Hint: If reason is ErrImageNeverPull/ImagePullBackOff, load local images into kind first:"
    Write-Host "  .\devops\kubernetes\setup-kind.ps1"
    exit 1
}

Write-Host "[6/6] Checking runtime resource usage (if metrics-server is installed)"
try {
    kubectl top pods -n $Namespace
}
catch {
    Write-Host "metrics-server not available; skipping 'kubectl top'"
}

Write-Host ""
Write-Host "Verification complete: workloads are scheduled and constrained by defined requests/limits."
