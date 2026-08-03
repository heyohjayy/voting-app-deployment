#!/bin/bash

# Exit immediately if any command fails.
set -e

# Trivy scans Docker images for known operating system
# and application dependency vulnerabilities.
#
# Jenkins builds a new Docker image during every pipeline run.
# Rather than hardcoding an image name, Jenkins passes the
# IMAGE_NAME environment variable to this script.
#
# Example:
#
# IMAGE_NAME=ohjayy/vote:a83d21f
#
# The Docker socket is mounted so Trivy can inspect the
# locally built image directly without pulling it from
# Docker Hub.
docker run --rm \
-v /var/run/docker.sock:/var/run/docker.sock \
security-trivy:1.0 \
image "$IMAGE_NAME" || true
