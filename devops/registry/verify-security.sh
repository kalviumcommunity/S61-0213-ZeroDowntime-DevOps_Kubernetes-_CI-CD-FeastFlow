#!/bin/bash

# Sprint #3 Security Verification Script
# Checks for common security issues in Docker registry setup

echo "======================================"
echo "Sprint #3 Security Verification"
echo "======================================"
echo ""

PASS_COUNT=0
FAIL_COUNT=0

# Test 1: Check for hardcoded Docker Hub tokens
echo "[1/5] Checking for hardcoded Docker Hub tokens..."
if grep -r "dckr_pat" . --exclude-dir=.git --exclude-dir=node_modules --exclude="*.log" -q 2>/dev/null; then
    echo "❌ FAIL: Hardcoded Docker Hub token found in code"
    echo "         Found in:"
    grep -r "dckr_pat" . --exclude-dir=.git --exclude-dir=node_modules --exclude="*.log" 2>/dev/null | head -3
    ((FAIL_COUNT++))
else
    echo "✅ PASS: No hardcoded Docker Hub tokens"
    ((PASS_COUNT++))
fi
echo ""

# Test 2: Check Git history for leaked credentials
echo "[2/5] Checking Git history for leaked credentials..."
if git log -p --all 2>/dev/null | grep -i "dckr_pat" -q; then
    echo "❌ FAIL: Docker Hub token found in Git history"
    echo "         This is a security risk! Rotate your token immediately."
    ((FAIL_COUNT++))
else
    echo "✅ PASS: No credentials in Git history"
    ((PASS_COUNT++))
fi
echo ""

# Test 3: Check for .env files in Git
echo "[3/5] Checking for tracked .env files..."
if git ls-files 2>/dev/null | grep -E "\.env$|\.env\.local" -q; then
    echo "❌ FAIL: .env files are tracked in Git"
    echo "         These might contain secrets. Found:"
    git ls-files | grep -E "\.env$|\.env\.local"
    ((FAIL_COUNT++))
else
    echo "✅ PASS: No .env files tracked in Git"
    ((PASS_COUNT++))
fi
echo ""

# Test 4: Verify workflow uses secrets correctly
echo "[4/5] Verifying CI workflow uses GitHub Secrets..."
if [ -f ".github/workflows/registry-ci.yml" ]; then
    if grep -q 'secrets\.DOCKERHUB_USERNAME' .github/workflows/registry-ci.yml && \
       grep -q 'secrets\.DOCKERHUB_TOKEN' .github/workflows/registry-ci.yml; then
        echo "✅ PASS: Workflow correctly uses GitHub Secrets"
        ((PASS_COUNT++))
    else
        echo "❌ FAIL: Workflow not using GitHub Secrets properly"
        ((FAIL_COUNT++))
    fi
else
    echo "⚠️  WARN: Workflow file not found at .github/workflows/registry-ci.yml"
fi
echo ""

# Test 5: Check .gitignore configuration
echo "[5/5] Verifying .gitignore protection..."
if [ -f ".gitignore" ]; then
    if grep -E "\.env|secrets" .gitignore -q; then
        echo "✅ PASS: .gitignore properly configured"
        ((PASS_COUNT++))
    else
        echo "⚠️  WARN: .gitignore should include .env patterns"
        echo "         Add these lines to .gitignore:"
        echo "         .env"
        echo "         .env.local"
        echo "         *.env"
    fi
else
    echo "⚠️  WARN: .gitignore not found"
fi
echo ""

# Summary
echo "======================================"
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "======================================"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All security checks passed!"
    echo ""
    echo "Next steps:"
    echo "1. Ensure GitHub Secrets are configured"
    echo "2. Trigger the workflow and check logs"
    echo "3. Verify credentials appear as *** in logs"
    echo "4. Confirm images pushed to Docker Hub"
    exit 0
else
    echo "❌ Security issues found. Fix them before proceeding."
    echo ""
    echo "See SETUP_GUIDE.md for detailed instructions."
    exit 1
fi
