#!/bin/bash

# Build and push script for Docker Hub
# Usage: ./build-and-push.sh your-dockerhub-username

if [ $# -eq 0 ]; then
    echo "Usage: $0 <dockerhub-username>"
    echo "Example: $0 myusername"
    exit 1
fi

USERNAME=$1
IMAGE_NAME="cyberpower-ups"
TAG="latest"
FULL_IMAGE="${USERNAME}/${IMAGE_NAME}:${TAG}"

echo "Building Docker image: ${FULL_IMAGE}"

# Build the image
docker build -t "${FULL_IMAGE}" .

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "To push to Docker Hub, run:"
    echo "docker login"
    echo "docker push ${FULL_IMAGE}"
    echo ""
    echo "Then update docker-compose.yml with:"
    echo "image: ${FULL_IMAGE}"
else
    echo "Build failed!"
    exit 1
fi