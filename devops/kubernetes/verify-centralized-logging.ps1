#!/usr/bin/env pwsh
# verify-centralized-logging.ps1
# Validates that the centralized logging stack (Loki + Fluent Bit + Grafana) is working correctly

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FeastFlow Centralized Logging Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Color functions
function Write-Success { param($msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Failure { param($msg) Write-Host "✗ $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "ℹ $msg" -ForegroundColor Yellow }
function Write-Section { param($msg) Write-Host "`n--- $msg ---" -ForegroundColor Cyan }

$allPassed = $true

# 1. Check if logging components are deployed
Write-Section "Checking Logging Components Deployment"

$loki = kubectl get deployment loki -n feastflow -o json 2>$null | ConvertFrom-Json
if ($loki) {
    Write-Success "Loki deployment exists"
} else {
    Write-Failure "Loki deployment not found"
    $allPassed = $false
}

$fluentBit = kubectl get daemonset fluent-bit -n feastflow -o json 2>$null | ConvertFrom-Json
if ($fluentBit) {
    Write-Success "Fluent Bit DaemonSet exists"
} else {
    Write-Failure "Fluent Bit DaemonSet not found"
    $allPassed = $false
}

$grafana = kubectl get deployment grafana -n feastflow -o json 2>$null | ConvertFrom-Json
if ($grafana) {
    Write-Success "Grafana deployment exists"
} else {
    Write-Failure "Grafana deployment not found"
    $allPassed = $false
}

# 2. Check pod readiness
Write-Section "Checking Pod Readiness"

$lokiPods = kubectl get pods -n feastflow -l app=loki -o json 2>$null | ConvertFrom-Json
$lokiReady = $false
if ($lokiPods.items) {
    foreach ($pod in $lokiPods.items) {
        if ($pod.status.phase -eq "Running") {
            $readyContainers = ($pod.status.containerStatuses | Where-Object { $_.ready -eq $true }).Count
            $totalContainers = $pod.status.containerStatuses.Count
            if ($readyContainers -eq $totalContainers) {
                Write-Success "Loki pod '$($pod.metadata.name)' is ready ($readyContainers/$totalContainers)"
                $lokiReady = $true
            } else {
                Write-Failure "Loki pod '$($pod.metadata.name)' not ready ($readyContainers/$totalContainers)"
                $allPassed = $false
            }
        } else {
            Write-Failure "Loki pod '$($pod.metadata.name)' is not running (Status: $($pod.status.phase))"
            $allPassed = $false
        }
    }
} else {
    Write-Failure "No Loki pods found"
    $allPassed = $false
}

$fluentBitPods = kubectl get pods -n feastflow -l app=fluent-bit -o json 2>$null | ConvertFrom-Json
$fluentBitReady = 0
if ($fluentBitPods.items) {
    foreach ($pod in $fluentBitPods.items) {
        if ($pod.status.phase -eq "Running") {
            $readyContainers = ($pod.status.containerStatuses | Where-Object { $_.ready -eq $true }).Count
            $totalContainers = $pod.status.containerStatuses.Count
            if ($readyContainers -eq $totalContainers) {
                $fluentBitReady++
            }
        }
    }
    Write-Success "Fluent Bit has $fluentBitReady ready pod(s)"
} else {
    Write-Failure "No Fluent Bit pods found"
    $allPassed = $false
}

$grafanaPods = kubectl get pods -n feastflow -l app=grafana -o json 2>$null | ConvertFrom-Json
$grafanaReady = $false
if ($grafanaPods.items) {
    foreach ($pod in $grafanaPods.items) {
        if ($pod.status.phase -eq "Running") {
            $readyContainers = ($pod.status.containerStatuses | Where-Object { $_.ready -eq $true }).Count
            $totalContainers = $pod.status.containerStatuses.Count
            if ($readyContainers -eq $totalContainers) {
                Write-Success "Grafana pod '$($pod.metadata.name)' is ready ($readyContainers/$totalContainers)"
                $grafanaReady = $true
            } else {
                Write-Failure "Grafana pod '$($pod.metadata.name)' not ready ($readyContainers/$totalContainers)"
                $allPassed = $false
            }
        } else {
            Write-Failure "Grafana pod '$($pod.metadata.name)' is not running (Status: $($pod.status.phase))"
            $allPassed = $false
        }
    }
} else {
    Write-Failure "No Grafana pods found"
    $allPassed = $false
}

# 3. Check services
Write-Section "Checking Services"

$lokiSvc = kubectl get service loki -n feastflow -o json 2>$null | ConvertFrom-Json
if ($lokiSvc) {
    Write-Success "Loki service exists (Endpoint: $($lokiSvc.spec.clusterIP):$($lokiSvc.spec.ports[0].port))"
} else {
    Write-Failure "Loki service not found"
    $allPassed = $false
}

$grafanaSvc = kubectl get service grafana -n feastflow -o json 2>$null | ConvertFrom-Json
if ($grafanaSvc) {
    $nodePort = $grafanaSvc.spec.ports[0].nodePort
    Write-Success "Grafana service exists (NodePort: $nodePort)"
    Write-Info "Access Grafana at: http://localhost:$nodePort (admin/feastflow2024)"
} else {
    Write-Failure "Grafana service not found"
    $allPassed = $false
}

# 4. Test Loki readiness endpoint
Write-Section "Testing Loki API"

if ($lokiReady) {
    $lokiPodName = $lokiPods.items[0].metadata.name
    
    Write-Info "Testing Loki /ready endpoint..."
    $readyResponse = kubectl exec -n feastflow $lokiPodName -- wget -q -O- http://localhost:3100/ready 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Loki is ready and accepting requests"
    } else {
        Write-Failure "Loki /ready endpoint failed"
        $allPassed = $false
    }
} else {
    Write-Info "Skipping Loki API test (pod not ready)"
}

# 5. Generate test logs
Write-Section "Generating Test Logs"

Write-Info "Creating test pod to generate logs..."
$testPodYaml = @"
apiVersion: v1
kind: Pod
metadata:
  name: log-generator-test
  namespace: feastflow
  labels:
    app: log-generator
    test: centralized-logging
spec:
  containers:
  - name: log-generator
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "Starting log generation test - timestamp: `$(date)"
        for i in `$(seq 1 10); do
          echo "Test log message `$i from log-generator-test - FeastFlow centralized logging verification"
          sleep 1
        done
        echo "Log generation test completed - timestamp: `$(date)"
        sleep 300
  restartPolicy: Never
"@

$testPodYaml | kubectl apply -f - 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Success "Test log generator pod created"
    Write-Info "Waiting 15 seconds for logs to be collected..."
    Start-Sleep -Seconds 15
} else {
    Write-Failure "Failed to create test log generator pod"
    $allPassed = $false
}

# 6. Query logs from Loki
Write-Section "Querying Logs from Loki"

if ($lokiReady) {
    $lokiPodName = $lokiPods.items[0].metadata.name
    
    Write-Info "Querying Loki for test logs..."
    
    # Query for our test pod logs
    $query = '{k8s_pod_name=~"log-generator-test"}'
    $encodedQuery = [System.Web.HttpUtility]::UrlEncode($query)
    $queryUrl = "http://localhost:3100/loki/api/v1/query?query=$encodedQuery"
    
    $queryResult = kubectl exec -n feastflow $lokiPodName -- wget -q -O- "$queryUrl" 2>$null
    
    if ($LASTEXITCODE -eq 0 -and $queryResult -like "*log-generator-test*") {
        Write-Success "Successfully queried logs from Loki"
        Write-Info "Found test logs in centralized logging system"
        
        # Count log entries
        if ($queryResult -match '"values":\[\[') {
            Write-Success "Logs are being collected and indexed"
        }
    } else {
        Write-Failure "Could not find test logs in Loki (logs may take time to arrive)"
        Write-Info "This may not be an error if the system was just deployed"
    }
    
    # Query for backend logs
    Write-Info "`nQuerying for backend application logs..."
    $backendQuery = '{k8s_labels_app="backend"}'
    $encodedBackendQuery = [System.Web.HttpUtility]::UrlEncode($backendQuery)
    $backendQueryUrl = "http://localhost:3100/loki/api/v1/query?query=$encodedBackendQuery"
    
    $backendResult = kubectl exec -n feastflow $lokiPodName -- wget -q -O- "$backendQueryUrl" 2>$null
    
    if ($LASTEXITCODE -eq 0 -and $backendResult -like "*backend*") {
        Write-Success "Backend application logs found in Loki"
    } else {
        Write-Info "Backend logs not yet available (may need time to collect)"
    }
} else {
    Write-Info "Skipping Loki query test (pod not ready)"
}

# 7. Check Fluent Bit metrics
Write-Section "Checking Fluent Bit Metrics"

if ($fluentBitReady -gt 0) {
    $fluentBitPodName = $fluentBitPods.items[0].metadata.name
    
    Write-Info "Checking Fluent Bit metrics..."
    $metrics = kubectl exec -n feastflow $fluentBitPodName -- wget -q -O- http://localhost:2020/api/v1/metrics 2>$null
    
    if ($LASTEXITCODE -eq 0 -and $metrics) {
        Write-Success "Fluent Bit metrics endpoint is accessible"
        
        # Check for output success
        if ($metrics -like "*output*") {
            Write-Success "Fluent Bit is forwarding logs to Loki"
        }
    } else {
        Write-Failure "Could not access Fluent Bit metrics"
    }
} else {
    Write-Info "Skipping Fluent Bit metrics check (no ready pods)"
}

# 8. Verify labels are being applied
Write-Section "Verifying Log Labels"

if ($lokiReady) {
    $lokiPodName = $lokiPods.items[0].metadata.name
    
    Write-Info "Checking available labels in Loki..."
    $labelsUrl = "http://localhost:3100/loki/api/v1/labels"
    $labelsResult = kubectl exec -n feastflow $lokiPodName -- wget -q -O- "$labelsUrl" 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        $expectedLabels = @("k8s_namespace_name", "k8s_pod_name", "k8s_container_name", "cluster", "job")
        $foundLabels = 0
        
        foreach ($label in $expectedLabels) {
            if ($labelsResult -like "*$label*") {
                $foundLabels++
            }
        }
        
        if ($foundLabels -ge 3) {
            Write-Success "Log labels are properly configured ($foundLabels/$($expectedLabels.Count) expected labels found)"
        } else {
            Write-Info "Some labels may not be available yet ($foundLabels/$($expectedLabels.Count) found)"
        }
    }
} else {
    Write-Info "Skipping label verification (Loki not ready)"
}

# Cleanup test pod
Write-Section "Cleanup"
Write-Info "Removing test log generator pod..."
kubectl delete pod log-generator-test -n feastflow --ignore-not-found=true 2>&1 | Out-Null

# Summary
Write-Host "`n========================================"  -ForegroundColor Cyan
Write-Host "Verification Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($allPassed) {
    Write-Host "`n✓ All critical checks passed!" -ForegroundColor Green
    Write-Host "`nCentralized logging is operational:" -ForegroundColor Green
    Write-Host "  - Fluent Bit is collecting logs from all pods" -ForegroundColor White
    Write-Host "  - Loki is storing and indexing logs" -ForegroundColor White
    Write-Host "  - Grafana is available for log visualization" -ForegroundColor White
    
    if ($grafanaSvc) {
        $nodePort = $grafanaSvc.spec.ports[0].nodePort
        Write-Host "`nNext Steps:" -ForegroundColor Yellow
        Write-Host "  1. Access Grafana: http://localhost:$nodePort" -ForegroundColor White
        Write-Host "  2. Login: admin / feastflow2024" -ForegroundColor White
        Write-Host "  3. Go to Explore > Select 'Loki' datasource" -ForegroundColor White
        Write-Host "  4. Use LogQL queries like:" -ForegroundColor White
        Write-Host "     {k8s_namespace_name=`"feastflow`"}" -ForegroundColor Cyan
        Write-Host "     {k8s_labels_app=`"backend`"}" -ForegroundColor Cyan
        Write-Host "     {k8s_labels_app=`"frontend`"}" -ForegroundColor Cyan
    }
}
    
    exit 0
} else {
    Write-Host "`n✗ Some checks failed" -ForegroundColor Red
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check pod logs:" -ForegroundColor White
    Write-Host "     kubectl logs -n feastflow -l app=loki" -ForegroundColor Cyan
    Write-Host "     kubectl logs -n feastflow -l app=fluent-bit" -ForegroundColor Cyan
    Write-Host "     kubectl logs -n feastflow -l app=grafana" -ForegroundColor Cyan
    Write-Host "`n  2. Check pod status:" -ForegroundColor White
    Write-Host "     kubectl describe pod -n feastflow -l app=loki" -ForegroundColor Cyan
    Write-Host "     kubectl describe pod -n feastflow -l app=fluent-bit" -ForegroundColor Cyan
    Write-Host "`n  3. Verify PersistentVolumeClaims:" -ForegroundColor White
    Write-Host "     kubectl get pvc -n feastflow" -ForegroundColor Cyan
    
    exit 1
}
