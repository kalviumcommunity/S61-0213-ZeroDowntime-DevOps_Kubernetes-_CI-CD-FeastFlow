#!/bin/bash

# push.sh
# Pushes all tagged FeastFlow frontend images to Docker Hub
# Prerequisites: Must have logged in via 'docker login'
# Usage: ./push.sh [DOCKERHUB_USERNAME]

set -e

# Configuration
SERVICE_NAME="feastflow-frontend"

# Get Docker Hub username (from argument or environment variable)
DOCKERHUB_USERNAME="${1:-${DOCKERHUB_USERNAME}}"

if [ -z "$DOCKERHUB_USERNAME" ]; then
    echo "❌ Error: DOCKERHUB_USERNAME not provided"
    echo "Usage: ./push.sh <dockerhub_username>"
    echo "   or: export DOCKERHUB_USERNAME=<your_username> && ./push.sh"
    exit 1
fi

# Get git commit SHA (short form)
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Define image name and tags
IMAGE_BASE="${DOCKERHUB_USERNAME}/${SERVICE_NAME}"
TAG_LATEST="latest"
TAG_SPRINT="sprint3"
TAG_COMMIT="commit-${GIT_COMMIT}"

echo "════════════════════════════════════════════════════════"
echo "🚀 Pushing FeastFlow Frontend to Docker Hub"
echo "════════════════════════════════════════════════════════"
echo "Repository:     ${IMAGE_BASE}"
echo "Docker Hub:     ${DOCKERHUB_USERNAME}"
echo "────────────────────────────────────────────────────────"

# Verify docker login
echo "🔐 Verifying Docker Hub authentication..."
if ! docker info | grep -q "Username: ${DOCKERHUB_USERNAME}"; then
    echo "⚠️  Warning: Not logged in to Docker Hub as ${DOCKERHUB_USERNAME}"
    echo "Run: docker login"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Push all tags
echo "📤 Pushing: ${IMAGE_BASE}:${TAG_COMMIT}"
docker push "${IMAGE_BASE}:${TAG_COMMIT}"

echo "📤 Pushing: ${IMAGE_BASE}:${TAG_LATEST}"
docker push "${IMAGE_BASE}:${TAG_LATEST}"

echo "📤 Pushing: ${IMAGE_BASE}:${TAG_SPRINT}"
docker push "${IMAGE_BASE}:${TAG_SPRINT}"

echo "════════════════════════════════════════════════════════"
echo "✅ Push Complete!"
echo "════════════════════════════════════════════════════════"
echo "🌐 View on Docker Hub:"
echo "   https://hub.docker.com/r/${DOCKERHUB_USERNAME}/${SERVICE_NAME}"
echo ""
echo "📥 Pull commands:"
echo "   docker pull ${IMAGE_BASE}:${TAG_LATEST}"
echo "   docker pull ${IMAGE_BASE}:${TAG_SPRINT}"
echo "   docker pull ${IMAGE_BASE}:${TAG_COMMIT}"
echo "════════════════════════════════════════════════════════"
echo ""
