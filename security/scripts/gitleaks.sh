#!/bin/bash

# Exit immediately if any command fails.
set -e

# GitLeaks scans the entire repository for potential hardcoded secrets.
#
# Unlike TruffleHog, GitLeaks acts as a Signal in this project.
# It reports findings for review while allowing the pipeline
# to continue.
#
# The WORKSPACE variable is supplied automatically by Jenkins.
docker run --rm \
-v "$WORKSPACE:/repo" \
security-gitleaks:1.0 \
dir /repo || true
