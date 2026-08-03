#!/bin/bash

set -e

echo "WORKSPACE=$WORKSPACE"
echo "SERVICE=$SERVICE"
echo "DOCKERFILE=$WORKSPACE/$SERVICE/Dockerfile"

ls -l "$WORKSPACE"
ls -l "$WORKSPACE/$SERVICE" || true

test -f "$WORKSPACE/$SERVICE/Dockerfile" && echo "Dockerfile found" || echo "Dockerfile NOT found"

docker run --rm -i \
security-hadolint:1.0 < "$WORKSPACE/$SERVICE/Dockerfile"
