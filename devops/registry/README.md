# Docker Registry Management

This directory contains scripts and documentation for managing Docker images and registry operations in the FeastFlow DevOps pipeline.

## 🚀 Sprint #3: Get Started Here

**New to this?** Follow the **[SETUP_GUIDE.md](SETUP_GUIDE.md)** for step-by-step instructions to:
1. ✅ Set up Docker Hub registry
2. ✅ Configure secure GitHub Secrets
3. ✅ Verify credentials are not exposed
4. ✅ Test image pushing
5. ✅ Complete security verification

## Contents

### 📖 Documentation

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - **[START HERE]** Step-by-step Sprint #3 implementation guide
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - One-page quick reference for Sprint #3
- **[dockerhub-usage.md](dockerhub-usage.md)** - Complete guide to building, tagging, and pushing images to Docker Hub

### 🔧 Scripts

- **[build-and-tag.sh](build-and-tag.sh)** - Build and tag images locally
- **[push.sh](push.sh)** - Push images to Docker Hub
- **[verify-security.sh](verify-security.sh)** - Security verification (Linux/macOS)
- **[verify-security.ps1](verify-security.ps1)** - Security verification (Windows)

## Quick Start for Local Development

```bash
# Set your Docker Hub username
export DOCKERHUB_USERNAME=yourusername

# Build and tag the image
./build-and-tag.sh

# Push to Docker Hub (requires docker login)
./push.sh
```

## Automated CI/CD

Images are automatically built and pushed by the GitHub Actions workflow at [`.github/workflows/registry-ci.yml`](../../.github/workflows/registry-ci.yml) on every push to `main`.

### How It Works

1. **Triggers** when you push to `main`
2. **Builds** frontend and backend Docker images
3. **Logs in** to Docker Hub **securely** using GitHub Secrets
4. **Pushes** images with multiple tags

### Tagging Strategy

- `commit-<sha>` - Immutable, maps to exact Git commit
- `build-<id>` - CI run number for traceability
- `latest` - Most recent build (convenience tag)

### 🔐 Security: GitHub Secrets Required

The workflow requires two repository secrets:
- `DOCKERHUB_USERNAME` - Your Docker Hub username
- `DOCKERHUB_TOKEN` - Docker Hub access token (**not** your password)

**Setup instructions**: See [SETUP_GUIDE.md](SETUP_GUIDE.md) Step 2-3

## Security Verification
 with automated script:

```bash
# Linux/macOS
./verify-security.sh

# Windows PowerShell
.\verify-security.ps1
```

**Manual checks:**
**Before submitting Sprint #3**, verify:

```bash
# 1. Check for hardcoded credentials (should return nothing)
grep -r "dckr_pat" . --exclude-dir=.git

# 2. Check Git history is clean (should return nothing)
git log -p --all | grep -i "dckr_pat"

# 3. Verify workflow logs show *** for credentials
# Go to Actions tab → Check "Log in to Docker Hub" step

# 4. Verify images on Docker Hub
# Visit hub.docker.com → Your repositories
```

## Additional Documentation

For detailed usage and advanced scenarios, see [dockerhub-usage.md](dockerhub-usage.md).
