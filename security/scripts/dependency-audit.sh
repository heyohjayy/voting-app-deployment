#!/bin/bash

# Exit immediately if any command fails.
set -e

# Each application uses a different programming language,
# so each requires a different dependency auditing tool.
#
# Vote    -> Python      -> pip-audit
# Worker  -> .NET        -> dotnet list package --vulnerable
# Result  -> Node.js     -> npm audit
#
# Jenkins passes the SERVICE variable to indicate which
# application is currently being built.
#
# Using one reusable script keeps the Jenkinsfiles much cleaner
# than maintaining three separate scripts.

case "$SERVICE" in

vote)

docker run --rm \
-v "$WORKSPACE/vote:/src" \
security-dependency-audit:1.0 \
sh -c "cd /src && pip-audit" || true

;;

worker)

docker run --rm \
-v "$WORKSPACE/worker:/src" \
security-dependency-audit:1.0 \
sh -c "cd /src && dotnet restore && dotnet list package --vulnerable" || true

;;

result)

docker run --rm \
-v "$WORKSPACE/result:/src" \
security-dependency-audit:1.0 \
sh -c "cd /src && npm install && npm audit --audit-level=high" || true

;;

*)

echo "Unknown service."

exit 1

;;

esac
