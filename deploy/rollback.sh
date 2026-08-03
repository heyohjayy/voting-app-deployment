#!/bin/bash

# Exit immediately if any command fails.
# A failed rollback should stop immediately so the issue can be investigated.
set -e

# Determine the absolute path of this script.
# This allows the rollback script to locate the deployment
# state files correctly regardless of where it is executed
# from (for example, manually or by a Jenkins pipeline).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${SCRIPT_DIR}/state"

# Verify that a service name has been supplied.
# The rollback script supports all three application services:
#
# vote
# worker
# result
#
# Example:
# bash deploy/rollback.sh vote
if [ -z "$1" ]; then
    echo "Usage: bash deploy/rollback.sh <vote|worker|result>"
    exit 1
fi

# Define the service passed to the rollback script.
# This allows a single rollback script to support the Vote,
# Worker, and Result services.
SERVICE="$1"

# Construct the Docker Hub image name for the selected service.
IMAGE="ohjayy/${SERVICE}"

# Define the files that store the deployment history.
#
# .current  -> the image tag currently running in production.
# .previous -> the last successfully deployed image tag.
#
# These files are maintained by the deployment scripts and are
# used by rollback.sh to restore the previous working release.
CURRENT_FILE="${STATE_DIR}/${SERVICE}.current"
PREVIOUS_FILE="${STATE_DIR}/${SERVICE}.previous"

# Verify that a previous deployment exists.
if [ ! -f "$PREVIOUS_FILE" ]; then
    echo "No previous deployment available for rollback."
    exit 1
fi

# Retrieve the previously deployed Docker image tag.
PREVIOUS_TAG=$(cat "$PREVIOUS_FILE")

echo "Rolling back ${SERVICE} service..."

# Pull the previous image from Docker Hub.
# This ensures Docker is using the exact image that was deployed
# successfully before the most recent deployment attempt.
docker pull ${IMAGE}:${PREVIOUS_TAG}

# Redeploy the selected service using its existing Docker Compose file.
docker compose -f ${SERVICE}/docker-compose.yml up -d

# Allow a few seconds for the container to restart completely.
sleep 10

# Verify that the service is running after the rollback.
if docker ps --filter "name=${SERVICE}" --filter "status=running" | grep -q "${SERVICE}"; then

    # The rolled-back version becomes the current production version.
    echo "${PREVIOUS_TAG}" > "$CURRENT_FILE"

    echo "Rollback completed successfully."

else

    echo "Rollback failed."

    exit 1

fi
