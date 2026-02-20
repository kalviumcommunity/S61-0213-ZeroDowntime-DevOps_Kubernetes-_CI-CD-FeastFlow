# Docker Registry Management

This directory contains scripts and documentation for managing Docker images and registry operations in the FeastFlow DevOps pipeline.

## Contents

- **[dockerhub-usage.md](dockerhub-usage.md)** - Complete guide to building, tagging, and pushing images to Docker Hub
- **[build-and-tag.sh](build-and-tag.sh)** - Script to build and tag images locally
- **[push.sh](push.sh)** - Script to push images to Docker Hub

## Quick Start

```bash
# Set your Docker Hub username
export DOCKERHUB_USERNAME=yourusername

# Build and tag the image
./build-and-tag.sh

# Push to Docker Hub (requires docker login)
./push.sh
```

## Automated CI/CD

Images are automatically built and pushed by the GitHub Actions workflow at `.github/workflows/registry-ci.yml` on every push to `main`.

## Documentation

For detailed instructions, scenarios, and troubleshooting, see [dockerhub-usage.md](dockerhub-usage.md).
