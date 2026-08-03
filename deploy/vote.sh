#!/bin/bash

# Exit immediately if any command fails.
set -e

# Determine the absolute path of this script.
# This allows the deployment scripts to locate the rollback
# state files correctly regardless of where they are executed
# from (for example, manually or by a Jenkins pipeline).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${SCRIPT_DIR}/state"

# Define the service and Docker Hub repository.
SERVICE="vote"
IMAGE="ohjayy/${SERVICE}"
TAG="${COMMIT_SHA}"

# Define the rollback state files.
CURRENT_FILE="${STATE_DIR}/${SERVICE}.current"
PREVIOUS_FILE="${STATE_DIR}/${SERVICE}.previous"

# Save the currently deployed image tag before deploying the new version.
# This allows rollback.sh to restore the last known working release.
if [ -f "$CURRENT_FILE" ]; then
    cp "$CURRENT_FILE" "$PREVIOUS_FILE"
elif docker ps --filter "name=${SERVICE}" --format "{{.Names}}" | grep -q "^${SERVICE}$"; then
    docker inspect ${SERVICE} \
        --format='{{.Config.Image}}' \
        | cut -d':' -f2 > "$CURRENT_FILE"

    cp "$CURRENT_FILE" "$PREVIOUS_FILE"
fi

echo "Deploying ${SERVICE} service..."

# Pull the new image from Docker Hub.
docker pull ${IMAGE}:${TAG}

# Deploy the updated service.
docker compose -f vote/docker-compose.yml up -d

# Wait for the container to become healthy.
sleep 10

# Verify the deployment.
if docker ps --filter "name=${SERVICE}" --filter "status=running" | grep -q "${SERVICE}"; then

    # Deployment succeeded.
    # Record the newly deployed version as the current release.
    echo "${TAG}" > "$CURRENT_FILE"

    echo "${SERVICE} deployment completed successfully."

else

    echo "Deployment failed. Rolling back..."

    bash "${SCRIPT_DIR}/rollback.sh" ${SERVICE}

    exit 1

fi
