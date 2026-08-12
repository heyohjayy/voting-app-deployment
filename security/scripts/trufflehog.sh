#!/bin/bash

# Exit immediately if any command fails.
# Since TruffleHog is configured as a Gate, any detected hard-coded secret
# immediately stops the CI/CD pipeline before any Docker image is built,
# published or deployed.
set -e

# Jenkins provides the WORKSPACE environment variable inside the Jenkins
# agent container. Resolve the corresponding workspace on the Docker host
# automatically so this script remains portable across environments.
HOST_WORKSPACE="$(docker inspect "$HOSTNAME" \
  --format '{{range .Mounts}}{{if eq .Destination "/home/jenkins/agent"}}{{.Source}}{{end}}{{end}}')/workspace/$(basename "$WORKSPACE")"

# Determine the commit range to scan.
#
# - On normal pipeline executions, scan only the commits introduced since the
#   previous successful build.
# - On the first pipeline execution, fall back to the repository's initial commit.
if [ -n "$GIT_PREVIOUS_SUCCESSFUL_COMMIT" ]; then
    BASE_COMMIT="$GIT_PREVIOUS_SUCCESSFUL_COMMIT"
elif [ -n "$GIT_PREVIOUS_COMMIT" ]; then
    BASE_COMMIT="$GIT_PREVIOUS_COMMIT"
else
    BASE_COMMIT=$(git -C "$WORKSPACE" rev-list --max-parents=0 HEAD)
fi

# Mount the repository into the TruffleHog container and scan only the commits
# introduced by the current pipeline execution.
#
# Restricting the scan to the new commit range prevents historical secrets
# from permanently blocking future builds while still stopping any newly
# committed GitHub Personal Access Token before the Docker image is built,
# published or deployed.
docker run --rm \
-v "${HOST_WORKSPACE}:/repo" \
security-trufflehog:1.0 \
git file:///repo \
--since-commit="$BASE_COMMIT" \
--branch="$(git -C "$WORKSPACE" rev-parse --abbrev-ref HEAD)" \
--include-detectors=Github \
--fail
