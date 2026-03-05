# Sprint #3 Security Verification Script (PowerShell)
# Checks for common security issues in Docker registry setup

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Sprint #3 Security Verification" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$passCount = 0
$failCount = 0

# Test 1: Check for hardcoded Docker Hub tokens
Write-Host "[1/5] Checking for hardcoded Docker Hub tokens..." -ForegroundColor Yellow
$tokenMatches = Get-ChildItem -Recurse -File -Exclude *.log | 
    Select-String -Pattern "dckr_pat" -ErrorAction SilentlyContinue

if ($tokenMatches) {
    Write-Host "❌ FAIL: Hardcoded Docker Hub token found in code" -ForegroundColor Red
    Write-Host "         Found in:" -ForegroundColor Red
    $tokenMatches | Select-Object -First 3 | ForEach-Object { 
        Write-Host "         $($_.Path):$($_.LineNumber)" -ForegroundColor Red 
    }
    $failCount++
} else {
    Write-Host "✅ PASS: No hardcoded Docker Hub tokens" -ForegroundColor Green
    $passCount++
}
Write-Host ""

# Test 2: Check Git history for leaked credentials
Write-Host "[2/5] Checking Git history for leaked credentials..." -ForegroundColor Yellow
$gitHistory = git log -p --all 2>$null | Select-String -Pattern "dckr_pat" -Quiet
if ($gitHistory) {
    Write-Host "❌ FAIL: Docker Hub token found in Git history" -ForegroundColor Red
    Write-Host "         This is a security risk! Rotate your token immediately." -ForegroundColor Red
    $failCount++
} else {
    Write-Host "✅ PASS: No credentials in Git history" -ForegroundColor Green
    $passCount++
}
Write-Host ""

# Test 3: Check for .env files in Git  
Write-Host "[3/5] Checking for tracked .env files..." -ForegroundColor Yellow
$envFiles = git ls-files 2>$null | Select-String -Pattern "\.env$|\.env\.local"
if ($envFiles) {
    Write-Host "❌ FAIL: .env files are tracked in Git" -ForegroundColor Red
    Write-Host "         These might contain secrets. Found:" -ForegroundColor Red
    $envFiles | ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
    $failCount++
} else {
    Write-Host "✅ PASS: No .env files tracked in Git" -ForegroundColor Green
    $passCount++
}
Write-Host ""

# Test 4: Verify workflow uses secrets correctly
Write-Host "[4/5] Verifying CI workflow uses GitHub Secrets..." -ForegroundColor Yellow
$workflowPath = ".github\workflows\registry-ci.yml"
if (Test-Path $workflowPath) {
    $workflowContent = Get-Content $workflowPath -Raw
    if ($workflowContent -match 'secrets\.DOCKERHUB_USERNAME' -and 
        $workflowContent -match 'secrets\.DOCKERHUB_TOKEN') {
        Write-Host "✅ PASS: Workflow correctly uses GitHub Secrets" -ForegroundColor Green
        $passCount++
    } else {
        Write-Host "❌ FAIL: Workflow not using GitHub Secrets properly" -ForegroundColor Red
        $failCount++
    }
} else {
    Write-Host "⚠️  WARN: Workflow file not found at $workflowPath" -ForegroundColor Yellow
}
Write-Host ""

# Test 5: Check .gitignore configuration
Write-Host "[5/5] Verifying .gitignore protection..." -ForegroundColor Yellow
if (Test-Path ".gitignore") {
    $gitignoreContent = Get-Content ".gitignore" -Raw
    if ($gitignoreContent -match '\.env|secrets') {
        Write-Host "✅ PASS: .gitignore properly configured" -ForegroundColor Green
        $passCount++
    } else {
        Write-Host "⚠️  WARN: .gitignore should include .env patterns" -ForegroundColor Yellow
        Write-Host "         Add these lines to .gitignore:" -ForegroundColor Yellow
        Write-Host "         .env" -ForegroundColor Yellow
        Write-Host "         .env.local" -ForegroundColor Yellow
        Write-Host "         *.env" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  WARN: .gitignore not found" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Results: $passCount passed, $failCount failed" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

if ($failCount -eq 0) {
    Write-Host "✅ All security checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Ensure GitHub Secrets are configured" -ForegroundColor White
    Write-Host "2. Trigger the workflow and check logs" -ForegroundColor White
    Write-Host "3. Verify credentials appear as *** in logs" -ForegroundColor White
    Write-Host "4. Confirm images pushed to Docker Hub" -ForegroundColor White
    exit 0
} else {
    Write-Host "❌ Security issues found. Fix them before proceeding." -ForegroundColor Red
    Write-Host ""
    Write-Host "See SETUP_GUIDE.md for detailed instructions." -ForegroundColor Yellow
    exit 1
}
