#!/bin/bash

# build-and-tag.sh
# Builds the FeastFlow frontend Docker image and applies multiple tags for registry management
# Usage: ./build-and-tag.sh [DOCKERHUB_USERNAME]

set -e

# Configuration
SERVICE_NAME="feastflow-frontend"
DOCKERFILE_PATH="../../frontend/app"
DOCKERFILE_NAME="Dockerfile"

# Get Docker Hub username (from argument or environment variable)
DOCKERHUB_USERNAME="${1:-${DOCKERHUB_USERNAME}}"

if [ -z "$DOCKERHUB_USERNAME" ]; then
    echo "❌ Error: DOCKERHUB_USERNAME not provided"
    echo "Usage: ./build-and-tag.sh <dockerhub_username>"
    echo "   or: export DOCKERHUB_USERNAME=<your_username> && ./build-and-tag.sh"
    exit 1
fi

# Get git commit SHA (short form)
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_ID="${BUILD_NUMBER:-local-$(date +%Y%m%d%H%M%S)}"

# Define image name and tags
IMAGE_BASE="${DOCKERHUB_USERNAME}/${SERVICE_NAME}"
TAG_LATEST="latest"
TAG_BUILD="build-${BUILD_ID}"
TAG_COMMIT="commit-${GIT_COMMIT}"

echo "════════════════════════════════════════════════════════"
echo "🐳 Building FeastFlow Frontend Docker Image"
echo "════════════════════════════════════════════════════════"
echo "Service:        ${SERVICE_NAME}"
echo "Dockerfile:     ${DOCKERFILE_PATH}/${DOCKERFILE_NAME}"
echo "Git Commit:     ${GIT_COMMIT}"
echo "Build ID:       ${BUILD_ID}"
echo "Docker Hub:     ${DOCKERHUB_USERNAME}"
echo "────────────────────────────────────────────────────────"

# Build the image with primary tag
echo "⚙️  Building image: ${IMAGE_BASE}:${TAG_COMMIT}"
docker build \
    -t "${IMAGE_BASE}:${TAG_COMMIT}" \
    -f "${DOCKERFILE_PATH}/${DOCKERFILE_NAME}" \
    "${DOCKERFILE_PATH}"

# Apply additional tags
echo "🏷️  Tagging image as: ${IMAGE_BASE}:${TAG_LATEST}"
docker tag "${IMAGE_BASE}:${TAG_COMMIT}" "${IMAGE_BASE}:${TAG_LATEST}"

echo "🏷️  Tagging image as: ${IMAGE_BASE}:${TAG_BUILD}"
docker tag "${IMAGE_BASE}:${TAG_COMMIT}" "${IMAGE_BASE}:${TAG_BUILD}"

echo "════════════════════════════════════════════════════════"
echo "✅ Build Complete! Created tags:"
echo "────────────────────────────────────────────────────────"
echo "   ${IMAGE_BASE}:${TAG_COMMIT}"
echo "   ${IMAGE_BASE}:${TAG_LATEST}"
echo "   ${IMAGE_BASE}:${TAG_BUILD}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "💡 Next steps:"
echo "   1. Test locally: docker run -p 3000:3000 ${IMAGE_BASE}:${TAG_COMMIT}"
echo "   2. Push to Docker Hub: ./push.sh ${DOCKERHUB_USERNAME}"
echo ""
