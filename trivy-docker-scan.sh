#!/bin/bash

# Variables
DOCKERFILE="Spring/Dockerfile"   
TRIVY_REPORT_HTML="trivy-report.html"
TRIVY_REPORT_XML="trivy-report.xml"

# Extract image names from the Dockerfile
IMAGES=$(grep "^FROM" "$DOCKERFILE" | awk '{print $2}')



# Run Trivy scan for each image and generate reports
for IMAGE in $IMAGES; do
    echo "Scanning image: $IMAGE"
    
    # Run Trivy for each image and generate an HTML report
    docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(pwd):/root/.cache/ \
    aquasec/trivy:latest image --format html -o "$IMAGE-$TRIVY_REPORT_HTML" "$IMAGE"
    
    # Generate XML report (JUnit format)
    docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(pwd):/root/.cache/ \
    aquasec/trivy:latest image --format template --template "@contrib/junit.tpl" -o "$IMAGE-$TRIVY_REPORT_XML" "$IMAGE"
done

echo "Trivy scans completed."

