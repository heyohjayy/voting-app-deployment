#!/bin/bash

# Exit immediately if any command fails
set -e

# Define the service and image name
SERVICE="vote"
IMAGE="ohjayy/${SERVICE}"

# Get the image tag from the Jenkins pipeline
TAG="${COMMIT_SHA}"

# Save the current image tag to allow rollback.sh read the saved tag.
docker inspect ${SERVICE} \
    --format='{{.Config.Image}}' \
    | cut -d':' -f2 > .previous-tag

echo "Deploying ${SERVICE} service..."

# Pull the latest image from Docker Hub
docker pull ${IMAGE}:${TAG}

# Recreate only the Vote service
docker compose -f vote/docker-compose.yml up -d

# Wait for the service to start
sleep 10

# Verify that the service is running
if docker ps --filter "name=${SERVICE}" --filter "status=running" | grep -q "${SERVICE}"; then
    echo "${SERVICE} deployment completed successfully."
else
    echo "Deployment failed. Rolling back vote service..."
    bash deploy/rollback.sh ${SERVICE}
    exit 1
fi
