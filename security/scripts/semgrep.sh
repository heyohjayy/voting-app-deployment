#!/bin/bash

# Exit immediately if any command fails.
set -e

# Semgrep performs static application security testing (SAST)
# by analysing the source code directly.
#
# The entire repository is mounted into the container so
# Semgrep can inspect all supported source files.
#
# The auto configuration downloads an appropriate collection
# of security rules based on the technologies detected in
# the repository.
docker run --rm \
-v "$WORKSPACE:/src" \
security-semgrep:1.0 \
semgrep scan --config=auto || true
