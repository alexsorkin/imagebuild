#!/usr/bin/env bash

# Run a curl against the Jenkins instance installed in a Dockerfile
# to do a basic health check

set -e
set -x

echo "Curling against the Jenkins server"
echo "Should expect a 403 within 5 seconds"
STATUS_CODE=$(curl -sL -w "%{http_code}" localhost:8080 -o /dev/null \
    --max-time 5)

if [[ "$STATUS_CODE" == "403" ]]; then
    echo "Jenkins has come up and ready to use"
    exit 0
else
    echo "Jenkins did not return a correct status code."
    echo "Returned: $STATUS_CODE"
    exit 1
fi
