#!/bin/bash

# Exit immediately if any command fails.
# Since TruffleHog is configured as a Gate, any detected hard-coded secret
# immediately stops the CI/CD pipeline before any Docker image is built,
# published or deployed.
set -e

# Jenkins automatically provides the WORKSPACE environment variable.
# Mount the repository into the container and scan the Git history for
# hard-coded GitHub Personal Access Tokens (PATs).
#
# The --fail flag causes TruffleHog to terminate the pipeline immediately
# when a GitHub PAT is detected, enforcing the Gate behaviour required
# for this project.
#
# TruffleHog supports many other secret detectors (AWS, Slack, Azure, etc.),
# but this implementation intentionally enables only the GitHub detector to
# demonstrate secret detection while avoiding unrelated findings from the
# sample application and third-party dependencies.
docker run --rm \
-v "$WORKSPACE:/repo" \
security-trufflehog:1.0 \
git \
--include-detectors=Github \
--fail \
file:///repo
