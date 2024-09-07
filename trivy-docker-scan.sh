#!/bin/bash

# Variables
DOCKERFILE="Spring/Dockerfile"

# Extract image names from the Dockerfile
IMAGES=$(grep "^FROM" "$DOCKERFILE" | awk '{print $2}')

# Run Trivy scan for each image and generate reports
for IMAGE in $IMAGES; do
    echo "Scanning image: $IMAGE"

    # Run Trivy for each image and generate an HTML report
    docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v $(pwd):/root/.cache/ \
        -v $(pwd)/html.tpl:/html.tpl \
        -v $(pwd):/output \
        aquasec/trivy:0.37.3 image --timeout 15m --format template --template "@/html.tpl" -o /output/${IMAGE}-trivy-report.html $IMAGE

    echo "Trivy scan for $IMAGE completed."
done

echo "All Trivy scans completed."

