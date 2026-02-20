# Docker Hub Registry Usage for FeastFlow

## Why Docker Registries Matter in FeastFlow CI/CD

Docker registries are the **critical bridge** between building container images and deploying them to Kubernetes. In the FeastFlow DevOps model, the artifact flow is:

```
Source Code (Git) → Build (CI) → Container Image → Registry (Docker Hub) → Deploy (Kubernetes Cluster)
```

Without a registry:

- Kubernetes nodes cannot pull images to run containers
- You cannot share images across development, staging, and production environments
- Rollbacks require rebuilding old code instead of redeploying existing images
- No centralized, versioned artifact storage for audit and compliance

**Docker Hub** serves as FeastFlow's central image repository, enabling:

1. **Environment Consistency** - The same `feastflow-frontend:commit-a1b2c3` image tested in staging runs in production
2. **Zero-Downtime Deployments** - Kubernetes pulls new images from the registry during rolling updates
3. **Rollback Capability** - Instantly redeploy `commit-xyz123` if `latest` introduces issues
4. **Team Collaboration** - All developers and CI/CD pipelines push/pull from a single source of truth

---

## Image Tagging Strategy

FeastFlow uses a **multi-tag strategy** to balance convenience, traceability, and rollback capability:

| Tag            | Purpose                      | Example                                      | Use Case                                 |
| -------------- | ---------------------------- | -------------------------------------------- | ---------------------------------------- |
| `latest`       | Most recent production build | `youruser/feastflow-frontend:latest`         | Quick deployments without version lookup |
| `sprint3`      | Stable milestone release     | `youruser/feastflow-frontend:sprint3`        | Demo, evaluation, and documentation      |
| `commit-<sha>` | Exact source code commit     | `youruser/feastflow-frontend:commit-a1b2c3d` | Precise rollback and audit trail         |

**Why three tags?**

- `latest` enables `docker pull youruser/feastflow-frontend` without specifying versions (convenience)
- `sprint3` provides a **named, immutable reference** for Sprint 3 evaluation
- `commit-<sha>` ensures **every deployed container maps back to exact source code** (Git SHA), critical for debugging production issues

---

## Prerequisites

Before using the registry workflow, ensure you have:

### 1. Docker Installed

Verify with:

```bash
docker --version
# Should output: Docker version 24.x or later
```

If not installed, follow the [official Docker installation guide](https://docs.docker.com/get-docker/).

### 2. Docker Hub Account

Create a free account at [hub.docker.com](https://hub.docker.com/) if you don't have one.

### 3. Docker Hub Login

Authenticate your local Docker daemon:

```bash
docker login
# Enter your Docker Hub username and password when prompted
```

**Verify login:**

```bash
docker info | grep Username
# Should display: Username: <your_dockerhub_username>
```

### 4. Environment Variable (Recommended)

Set your Docker Hub username to avoid passing it as an argument every time:

**Linux/macOS/WSL:**

```bash
export DOCKERHUB_USERNAME=<your_dockerhub_username>
```

**Windows PowerShell:**

```powershell
$env:DOCKERHUB_USERNAME = "<your_dockerhub_username>"
```

To make this persistent, add it to your shell profile (`~/.bashrc`, `~/.zshrc`, or PowerShell profile).

---

## Step-by-Step Workflow

### Step 1: Navigate to the Registry Scripts Directory

```bash
cd devops/registry
```

### Step 2: Build and Tag the Image

Run the build script to create a multi-stage Docker image with all three tags:

```bash
./build-and-tag.sh
```

**Or explicitly provide your username:**

```bash
./build-and-tag.sh yourusername
```

**What happens:**

1. Reads your latest Git commit SHA (e.g., `a1b2c3d`)
2. Builds the frontend Docker image from `frontend/app/Dockerfile`
3. Tags the image with:
   - `yourusername/feastflow-frontend:commit-a1b2c3d`
   - `yourusername/feastflow-frontend:latest`
   - `yourusername/feastflow-frontend:sprint3`

**Expected output:**

```
════════════════════════════════════════════════════════
🐳 Building FeastFlow Frontend Docker Image
════════════════════════════════════════════════════════
Service:        feastflow-frontend
Dockerfile:     ../../frontend/app/Dockerfile
Git Commit:     a1b2c3d
Docker Hub:     yourusername
────────────────────────────────────────────────────────
⚙️  Building image: yourusername/feastflow-frontend:commit-a1b2c3d
[Docker build output...]
🏷️  Tagging image as: yourusername/feastflow-frontend:latest
🏷️  Tagging image as: yourusername/feastflow-frontend:sprint3
════════════════════════════════════════════════════════
✅ Build Complete! Created tags:
────────────────────────────────────────────────────────
   yourusername/feastflow-frontend:commit-a1b2c3d
   yourusername/feastflow-frontend:latest
   yourusername/feastflow-frontend:sprint3
════════════════════════════════════════════════════════
```

### Step 3: Test the Image Locally (Optional but Recommended)

Before pushing to Docker Hub, verify the image works:

```bash
docker run -p 3000:3000 yourusername/feastflow-frontend:commit-a1b2c3d
```

Open [http://localhost:3000](http://localhost:3000) in your browser. You should see the FeastFlow frontend.

Press `Ctrl+C` to stop the container when done.

### Step 4: Push Images to Docker Hub

Upload all three tags to Docker Hub:

```bash
./push.sh
```

**Or with explicit username:**

```bash
./push.sh yourusername
```

**What happens:**

1. Verifies you're logged in to Docker Hub
2. Pushes all three tags (`commit-<sha>`, `latest`, `sprint3`) to your Docker Hub repository
3. Provides links to view the images on Docker Hub

**Expected output:**

```
════════════════════════════════════════════════════════
🚀 Pushing FeastFlow Frontend to Docker Hub
════════════════════════════════════════════════════════
Repository:     yourusername/feastflow-frontend
Docker Hub:     yourusername
────────────────────────────────────────────────────────
🔐 Verifying Docker Hub authentication...
📤 Pushing: yourusername/feastflow-frontend:commit-a1b2c3d
[Docker push output...]
📤 Pushing: yourusername/feastflow-frontend:latest
📤 Pushing: yourusername/feastflow-frontend:sprint3
════════════════════════════════════════════════════════
✅ Push Complete!
════════════════════════════════════════════════════════
🌐 View on Docker Hub:
   https://hub.docker.com/r/yourusername/feastflow-frontend
```

### Step 5: Verify on Docker Hub

1. Visit `https://hub.docker.com/r/<yourusername>/feastflow-frontend`
2. You should see three tags: `latest`, `sprint3`, and `commit-<sha>`
3. Each tag shows the image size, last push time, and digest

### Step 6: Pull and Run from Registry

Anyone with Docker can now pull your image:

```bash
# Pull the latest version
docker pull yourusername/feastflow-frontend:latest

# Pull a specific commit for rollback
docker pull yourusername/feastflow-frontend:commit-a1b2c3d

# Pull the Sprint 3 milestone
docker pull yourusername/feastflow-frontend:sprint3
```

**Run the pulled image:**

```bash
docker run -p 3000:3000 yourusername/feastflow-frontend:sprint3
```

---

## Real-World Scenarios for Video Demo

### Scenario 1: Standard Development Workflow

**Context:** You've just merged a new feature to the `main` branch and need to deploy it to staging.

**Steps:**

1. Pull the latest code: `git pull origin main`
2. Build the image: `./build-and-tag.sh`
3. Push to Docker Hub: `./push.sh`
4. Deploy to staging: Kubernetes pulls `yourusername/feastflow-frontend:latest` (or in a real setup, update Kubernetes manifest to reference the new `commit-<sha>` tag)

**Key Talking Points:**

- "The `commit-<sha>` tag ensures we know exactly what code is running in staging"
- "If this build passes QA, we promote the same image to production—no rebuild needed"

---

### Scenario 2: Rollback After Failed Deployment

**Context:** The latest deployment (`commit-e4f5g6h`) introduced a critical bug causing 500 errors. You need to roll back immediately.

**Problem:**

```bash
# Current broken deployment
kubectl get pods
# Shows: feastflow-frontend-e4f5g6h-xxx (CrashLoopBackOff)
```

**Solution:**

```bash
# Check Docker Hub for the previous working version
docker images --filter=reference="yourusername/feastflow-frontend:commit-*"

# Output shows:
# yourusername/feastflow-frontend:commit-a1b2c3d (last known good version)
# yourusername/feastflow-frontend:commit-e4f5g6h (current broken version)

# Pull the last known good version
docker pull yourusername/feastflow-frontend:commit-a1b2c3d

# Update Kubernetes deployment (simplified example)
kubectl set image deployment/feastflow-frontend \
  frontend=yourusername/feastflow-frontend:commit-a1b2c3d

# Verify rollback
kubectl rollout status deployment/feastflow-frontend
```

**Key Talking Points:**

- "Because every image is tagged with its Git commit, we can roll back to any previous version in seconds"
- "We don't need to rebuild old code—the image is already stored in Docker Hub"
- "The Git SHA (`a1b2c3d`) maps to a specific commit in GitHub, so we can trace what code was running at any time"

---

### Scenario 3: Running Teammate's Branch Locally

**Context:** Your teammate pushed a branch with a new pricing algorithm. You want to test their changes locally without checking out their branch.

**Steps:**

```bash
# Teammate builds and pushes from their branch (commit b2c3d4e)
# (They run build-and-tag.sh and push.sh from their branch)

# You pull their specific commit image
docker pull yourusername/feastflow-frontend:commit-b2c3d4e

# Run it locally
docker run -p 3000:3000 yourusername/feastflow-frontend:commit-b2c3d4e

# Test the new pricing logic at http://localhost:3000
```

**Key Talking Points:**

- "Docker registries enable collaboration—I can test any branch without switching my local Git state"
- "This is especially useful for code review: pull the reviewer's image, test it, then approve the PR"

---

### Scenario 4: Kubernetes Pulls from Registry During Deployment

**Context:** Demonstrating how Kubernetes uses the registry in a rolling update.

**Kubernetes Deployment Manifest (simplified):**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: feastflow-frontend
spec:
  replicas: 3
  template:
    spec:
      containers:
        - name: frontend
          image: yourusername/feastflow-frontend:commit-a1b2c3d
          ports:
            - containerPort: 3000
```

**What happens during `kubectl apply`:**

1. Kubernetes reads the manifest and sees `image: yourusername/feastflow-frontend:commit-a1b2c3d`
2. Each node pulls the image from Docker Hub (if not cached)
3. Kubernetes starts new pods with the updated image
4. Health checks pass, traffic shifts to new pods
5. Old pods are terminated

**Key Talking Points:**

- "The registry is the source of truth—Kubernetes never builds images, only pulls them"
- "This separation (build in CI, store in registry, deploy from registry) is the foundation of GitOps"
- "If Docker Hub is down, Kubernetes can still use cached images, but new nodes can't pull"

---

## CI/CD Integration (Automated Workflow)

For automated builds in GitHub Actions, see the CI workflow at `.github/workflows/registry-ci.yml`.

**Key differences from manual workflow:**

- CI uses **repository secrets** (`DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`) instead of interactive login
- Automatically tags images with the GitHub Actions commit SHA: `${{ github.sha }}`
- Only pushes to Docker Hub on `main` branch or specific tags to avoid polluting the registry with every feature branch

---

## Troubleshooting

### Error: "denied: requested access to the resource is denied"

**Cause:** Not logged in or using the wrong username.

**Solution:**

```bash
docker login
# Enter your Docker Hub credentials

# Or use an access token (recommended for CI):
echo $DOCKERHUB_TOKEN | docker login -u $DOCKERHUB_USERNAME --password-stdin
```

---

### Error: "Cannot connect to the Docker daemon"

**Cause:** Docker Desktop is not running (Windows/macOS) or `dockerd` service is stopped (Linux).

**Solution:**

- **Windows/macOS:** Start Docker Desktop
- **Linux:** `sudo systemctl start docker`

---

### Error: "repository name must be lowercase"

**Cause:** Docker Hub repositories must be lowercase (e.g., `yourusername/feastflow-frontend`, not `YourUsername/FeastFlow-Frontend`).

**Solution:** Update your `DOCKERHUB_USERNAME` to lowercase.

---

### Images pushed but not visible on Docker Hub

**Cause:** Repository is private by default.

**Solution:** Go to Docker Hub → Your repository → Settings → Make Public (if appropriate).

---

## Next Steps

1. **Integrate with Kubernetes:** Update Kubernetes manifests to reference your Docker Hub images (e.g., `yourusername/feastflow-frontend:sprint3`)
2. **Automate with CI:** Trigger `registry-ci.yml` workflow on every push to `main` to auto-build and push images
3. **Add other services:** Repeat this process for backend microservices (pricing, menu, order, etc.)
4. **Implement image scanning:** Use Docker Hub vulnerability scanning or integrate Trivy/Clair in CI
5. **Set up image retention policies:** Delete old commit tags (e.g., older than 90 days) to save storage

---

## Additional Resources

- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [Docker Build Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes Image Pull Policy](https://kubernetes.io/docs/concepts/containers/images/)
- [FeastFlow Container Strategy](../container-concepts/feastflow-container-strategy.md)
