Param(
    [string]$Namespace = "feastflow",
    [switch]$SkipAutoSetup
)

$ErrorActionPreference = "Stop"

$setupScript = Join-Path $PSScriptRoot "setup-kind.ps1"
$verifyScript = Join-Path $PSScriptRoot "verify-persistence.ps1"

Write-Host "============================================================"
Write-Host "FeastFlow Persistence Quick Check"
Write-Host "Namespace: $Namespace"
Write-Host "============================================================"

$clusterReachable = $false
try {
    kubectl cluster-info *> $null
    if ($LASTEXITCODE -eq 0) {
        $clusterReachable = $true
    }
} catch {
    $clusterReachable = $false
}

if (-not $clusterReachable) {
    if ($SkipAutoSetup) {
        Write-Host "FAIL: cluster not reachable (auto-setup skipped)." -ForegroundColor Red
        exit 1
    }

    Write-Host "Cluster not reachable. Running setup-kind.ps1..." -ForegroundColor Yellow
    & $setupScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAIL: setup-kind.ps1 failed." -ForegroundColor Red
        exit 1
    }

    try {
        kubectl config use-context kind-feastflow-local *> $null
    } catch {
        # Context switch may fail if context name differs; connectivity check below is authoritative.
    }

    $clusterReachable = $false
    try {
        kubectl cluster-info *> $null
        if ($LASTEXITCODE -eq 0) {
            $clusterReachable = $true
        }
    } catch {
        $clusterReachable = $false
    }

    if (-not $clusterReachable) {
        Write-Host "FAIL: cluster still not reachable after setup." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Waiting for cluster nodes to be Ready..." -ForegroundColor Yellow
$nodesReady = $false
for ($i = 1; $i -le 60; $i++) {
    try {
        $nodesJson = kubectl get nodes -o json 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($nodesJson)) {
            $nodes = ($nodesJson | ConvertFrom-Json).items
            if ($null -ne $nodes -and $nodes.Count -gt 0) {
                $allReady = $true
                foreach ($node in $nodes) {
                    $readyCondition = $node.status.conditions | Where-Object { $_.type -eq "Ready" } | Select-Object -First 1
                    if ($null -eq $readyCondition -or $readyCondition.status -ne "True") {
                        $allReady = $false
                        break
                    }
                }

                if ($allReady) {
                    $nodesReady = $true
                    break
                }
            }
        }
    } catch {
        $nodesReady = $false
    }
    Start-Sleep -Seconds 2
}

if (-not $nodesReady) {
    Write-Host "FAIL: nodes did not become Ready in time." -ForegroundColor Red
    kubectl get nodes
    exit 1
}

& $verifyScript -Namespace $Namespace
if ($LASTEXITCODE -eq 0) {
    Write-Host "PASS: persistence working" -ForegroundColor Green
    exit 0
}

Write-Host "FAIL: persistence not working" -ForegroundColor Red
exit 1
