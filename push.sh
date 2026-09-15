#!/bin/bash
# docker buildx create --name multiarch-builder --use
# chmod +x ./push.sh
DOCKERHUB_USER="gnasello"
CONTAINER_NAME="slicer-env"
VERSION="2026-08-27.2"

# Load the image
docker push "${DOCKERHUB_USER}/${CONTAINER_NAME}:${VERSION}"

# Update the latest tag
docker tag "${DOCKERHUB_USER}/${CONTAINER_NAME}:${VERSION}" "${DOCKERHUB_USER}/${CONTAINER_NAME}:latest"
docker push "${DOCKERHUB_USER}/${CONTAINER_NAME}:latest"
