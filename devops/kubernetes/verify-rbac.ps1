Param(
    [string]$Namespace = "feastflow",
    [string]$ServiceAccount = "feastflow-readonly-sa"
)

$ErrorActionPreference = "Stop"
$AsUser = "system:serviceaccount:${Namespace}:${ServiceAccount}"

function Invoke-KubectlChecked {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & kubectl @Arguments 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorAction

    if ($exitCode -ne 0) {
        throw "kubectl $($Arguments -join ' ') failed.`n$output"
    }

    return $output.Trim()
}

Write-Host "============================================================"
Write-Host "FeastFlow Kubernetes RBAC Verification"
Write-Host "Namespace: $Namespace"
Write-Host "ServiceAccount: $ServiceAccount"
Write-Host "============================================================"

Write-Host "[1/5] Checking cluster connectivity"
Invoke-KubectlChecked -Arguments @("cluster-info") | Out-Null

Write-Host "[2/5] Applying namespace and RBAC manifest"
Invoke-KubectlChecked -Arguments @("apply", "-f", "devops/kubernetes/00-namespace.yaml") | Out-Null
Invoke-KubectlChecked -Arguments @("apply", "-f", "devops/kubernetes/14-rbac-basics.yaml") | Out-Null

Write-Host "[3/5] Verifying allowed access (should be yes)"
$allowedPods = Invoke-KubectlChecked -Arguments @("auth", "can-i", "--as=$AsUser", "-n", $Namespace, "list", "pods")
$allowedDeployments = Invoke-KubectlChecked -Arguments @("auth", "can-i", "--as=$AsUser", "-n", $Namespace, "get", "deployments")

Write-Host "can-i list pods: $allowedPods"
Write-Host "can-i get deployments: $allowedDeployments"

if ($allowedPods.Trim() -ne "yes" -or $allowedDeployments.Trim() -ne "yes") {
    throw "Expected allowed read actions were denied."
}

Write-Host "[4/5] Verifying denied access (should be no)"
$deniedDeletePods = Invoke-KubectlChecked -Arguments @("auth", "can-i", "--as=$AsUser", "-n", $Namespace, "delete", "pods")
$deniedCreateSecrets = Invoke-KubectlChecked -Arguments @("auth", "can-i", "--as=$AsUser", "-n", $Namespace, "create", "secrets")

Write-Host "can-i delete pods: $deniedDeletePods"
Write-Host "can-i create secrets: $deniedCreateSecrets"

if ($deniedDeletePods.Trim() -ne "no" -or $deniedCreateSecrets.Trim() -ne "no") {
    throw "Expected denied write/admin actions were allowed."
}

Write-Host "[5/5] Triggering one real forbidden action (expected failure)"
$previousErrorAction = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$forbiddenOutput = kubectl --as=$AsUser -n $Namespace get secrets 2>&1 | Out-String
$forbiddenExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorAction

Write-Host $forbiddenOutput

if ($forbiddenExitCode -eq 0) {
    throw "get secrets unexpectedly succeeded."
}

if ($forbiddenOutput -notmatch "Forbidden") {
    throw "Forbidden response was expected but not detected."
}

Write-Host ""
Write-Host "✅ RBAC verified: read-only access allowed, mutating/secret access denied."
Write-Host "   Principal: $AsUser"