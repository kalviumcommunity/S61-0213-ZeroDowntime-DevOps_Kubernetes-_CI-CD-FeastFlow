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

## 🐳 Using Docker Hub

Docker Hub is a cloud-based registry for storing and sharing container images. In this project, Docker Hub is used to push, pull, and manage images for CI/CD workflows.

### Basic Usage

1. **Login to Docker Hub**
	```
	docker login
	```
	Enter your Docker Hub username and password or use a personal access token.

2. **Build an Image**
	```
	docker build -t <username>/<repo>:<tag> .
	```

3. **Tag an Image**
	```
	docker tag <local-image> <username>/<repo>:<tag>
	```

4. **Push to Docker Hub**
	```
	docker push <username>/<repo>:<tag>
	```

5. **Pull from Docker Hub**
	```
	docker pull <username>/<repo>:<tag>
	```

### Best Practices
- Use secure credentials and GitHub Secrets for automation
- Tag images with meaningful version numbers
- Remove unused images to save space
- Review [dockerhub-usage.md](dockerhub-usage.md) for advanced workflows and troubleshooting

---
## 💾 Persistence in Registry Operations

Persistence ensures that Docker images and registry data are reliably stored and remain available across container restarts, deployments, and system failures. In DevOps pipelines, persistent storage is critical for:

- Retaining built images for future deployments
- Enabling rollback to previous versions
- Supporting disaster recovery and high availability
- Maintaining audit logs and metadata

When using a self-hosted registry or cloud registry, configure persistent volumes (PVCs) in Kubernetes or use managed storage solutions to avoid data loss. Always verify that your registry's storage backend is properly set up and monitored.

For more details, see the Kubernetes PVC and deployment YAML files in the `devops/kubernetes/` directory.
## 🛠️ Rollback, Failure Simulation, and Deployment Validation 

This section demonstrates operational confidence under failure by simulating, detecting, and recovering from deployment issues in Kubernetes.

### 1. Simulate a Failure
- Edit your deployment YAML (e.g., `06-backend-deployment.yaml`) to use a broken image tag or misconfigured probe.
- Apply the change:
	```
	kubectl apply -f devops/kubernetes/06-backend-deployment.yaml
	```
- Observe pod status:
	```
	kubectl get pods
	kubectl describe pod <pod-name>
	kubectl logs <pod-name>
	```
	Pods should show errors like `CrashLoopBackOff` or `ImagePullBackOff`.

### 2. Rollback to Known-Good Version
- Roll back the deployment:
	```
	kubectl rollout undo deployment/backend-deployment
	```
- Verify recovery:
	```
	kubectl rollout status deployment/backend-deployment
	kubectl get pods
	```

### 3. Validate Recovery
	```
	kubectl get pods
	```
	```
	curl http://<service-ip>:<port>
	```
	Should return expected response.

## 🌐 Verifying Ingress Configuration

To ensure your Kubernetes ingress is working correctly:

1. Apply the ingress resource:
	```
	kubectl apply -f devops/kubernetes/10-ingress.yaml
	```
2. Check ingress status:
	```
	kubectl get ingress
	kubectl describe ingress <ingress-name>
	```
3. Test access from your browser or with curl:
	```
	curl http://localhost/<path>
	```
4. Confirm external IP or hostname is assigned and routes traffic to the correct service.
5. Review logs for errors and validate TLS if enabled.


### 4. Why Rollback Matters
Rollback is a first-class deployment strategy in Kubernetes, enabling safe recovery from failures and minimizing downtime. Always validate that your application recovers and traffic is restored after rollback.
## 🐞 Debugging & Troubleshooting

If you encounter issues with Docker registry operations, try the following:

- **Check Docker login:**
	- Run `docker login` and verify credentials.
- **Verify image tags:**
	- Ensure image tags match your repository and are not duplicated.
- **Check script permissions:**
	- On Linux/macOS, run `chmod +x *.sh` to make scripts executable.
- **Review logs:**
	- Use `docker logs <container>` for running containers.
- **Network issues:**
	- Ensure your network allows access to Docker Hub and registry endpoints.
- **Security verification:**
	- Run `verify-security.sh` or `verify-security.ps1` to check for exposed credentials.

For more troubleshooting, see [dockerhub-usage.md](dockerhub-usage.md) and [QUICK_REFERENCE.md](QUICK_REFERENCE.md).

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
# Deploy the logging stack
cd devops\kubernetes
.\deploy-logging.ps1

# Verify everything is working
.\verify-centralized-logging.ps1

# Access Grafana
# URL: http://localhost:30300
# Username: admin
# Password: feastflow2024