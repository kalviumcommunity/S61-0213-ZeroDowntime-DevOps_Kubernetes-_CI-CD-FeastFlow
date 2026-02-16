CI/CD Artifact Flow

Source → Image → Registry → Cluster

=>Objective

To understand how a Git commit becomes a deployable artifact and runs inside a Kubernetes cluster using a CI/CD pipeline.

🔁 Artifact Flow Overview

In modern DevOps, code is not deployed directly.
Each change becomes an immutable artifact that moves through controlled stages:

Source (Git Commit)
        ↓
CI Pipeline
        ↓
Docker Image
        ↓
Container Registry
        ↓
Kubernetes Cluster

1️⃣ Source (Git)

Developer pushes code or merges a Pull Request

Each commit has a unique commit hash

The commit triggers the CI pipeline

The commit identifies exactly what version of code is being built.

2️⃣ CI Pipeline

The CI pipeline (e.g., GitHub Actions):

Checks out code

Runs tests

Builds a Docker image

Tags the image

Pushes it to a registry

CI produces a Docker image artifact — it does not deploy source code directly.

3️⃣ Docker Image (Immutable Artifact)

A Docker image contains:

Application code

Dependencies

Runtime

Configuration

Images are immutable.
Every new commit creates a new image.

Example:

app:commit-a1b2
app:commit-c3d4

4️⃣ Image Tags and Digests

Image Tags
Human-readable labels (latest, v1.2.0, commit-xyz).

Image Digests
Cryptographic identifiers (sha256:...) that guarantee the exact image version.

5️⃣ Container Registry

Images are stored in a registry (Docker Hub, GitHub Container Registry, AWS ECR).

Registries provide:

Version storage

Traceability (image → commit)

Secure access

Kubernetes pulls images from the registry.

6️⃣ Kubernetes Deployment

Kubernetes runs the image in the cluster.

Deployment defines:

Image name

Tag/version

Replicas

Rolling update strategy

When the image changes, Kubernetes performs a rolling update without downtime.

🔄 Rollbacks

If a release fails:

Identify the previous stable image

Update deployment to that image

Kubernetes rolls back automatically

Rollbacks are safe because:

Images are immutable

Registry stores history

Deployments reference exact versions