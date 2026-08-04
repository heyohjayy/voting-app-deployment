#!/bin/bash

# Exit immediately if any command fails.
# Since TruffleHog is configured as a Gate, any detected hard-coded secret
# immediately stops the CI/CD pipeline before any Docker image is built,
# published or deployed.
set -e

# Jenkins provides the WORKSPACE environment variable inside the Jenkins
# container. Because Docker commands are executed through the host Docker
# daemon, the Jenkins workspace must be referenced using its corresponding
# Docker volume path on the host.
HOST_WORKSPACE="/var/lib/docker/volumes/jenkins_home/_data/workspace/$(basename "$WORKSPACE")"

# Mount the repository into the container and scan the repository filesystem
# for hard-coded GitHub Personal Access Tokens (PATs).
#
# The --include-detectors flag restricts the scan to GitHub tokens only,
# avoiding unrelated findings from the sample application and third-party
# dependencies.
#
# The --fail flag causes TruffleHog to terminate the pipeline immediately
# when a GitHub PAT is detected, enforcing the Gate behaviour required for
# this project.
docker run --rm \
-v "${HOST_WORKSPACE}:/repo" \
security-trufflehog:1.0 \
filesystem \
--include-detectors=Github \
--fail \
/repo
