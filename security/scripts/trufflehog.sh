#!/bin/bash

# Exit immediately if any command fails.
# Since TruffleHog is configured as a Gate, any failure should stop the pipeline.
set -e

# Jenkins automatically provides the WORKSPACE environment variable.
# WORKSPACE points to the root directory of the repository that Jenkins
# has checked out for the current build.
#
# We mount that directory into the container as /repo so TruffleHog can
# scan the entire repository for verified secrets.
echo "WORKSPACE=$WORKSPACE"
pwd
ls -la
ls -la "$WORKSPACE"
find "$WORKSPACE" -name "test-secret.txt"
docker run --rm \
-v "$WORKSPACE:/repo" \
security-trufflehog:1.0 \
filesystem /repo
