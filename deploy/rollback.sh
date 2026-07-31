#!/bin/bash

# Exit immediately if any command fails
set -e

# Define the service and image name
SERVICE=$1
IMAGE="ohjayy/${SERVICE}"

# Retrieve the previous image tag
PREVIOUS_TAG=$(cat .previous-tag)

echo "Rolling back ${SERVICE} service..."

# Pull the previous image from Docker Hub
docker pull ${IMAGE}:${PREVIOUS_TAG}

# Roll back to the previous image
IMAGE_TAG=${PREVIOUS_TAG} docker compose up -d --no-deps ${SERVICE}

# Wait for the service to restart
sleep 10

# Verify that the rollback was successful
if docker ps --filter "name=${SERVICE}" --filter "status=running" | grep -q "${SERVICE}"; then
    echo "Rollback completed successfully."
else
    echo "Rollback failed."
    exit 1
fi
