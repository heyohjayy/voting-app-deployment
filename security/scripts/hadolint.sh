#!/bin/bash

# Exit immediately if any command fails.
set -e

# Each pipeline (Vote, Worker and Result) builds a different Dockerfile.
#
# Instead of creating three separate Hadolint scripts,
# Jenkins tells this script which service is currently
# being built by passing the SERVICE environment variable.
#
# Examples:
#
# SERVICE=vote
# SERVICE=worker
# SERVICE=result
#
# The correct Dockerfile is then linted automatically.
docker run --rm -i \
security-hadolint:1.0 - < "$WORKSPACE/$SERVICE/Dockerfile" || true
