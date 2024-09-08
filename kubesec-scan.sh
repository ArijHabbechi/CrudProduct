#!/bin/bash

# File to scan
K8S_FILE="springapp-deployment.yml"

# Run Kubesec scan using the Docker image 
scan_result=$(docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin < "$K8S_FILE")


scan_message=$(echo "$scan_result" | jq -r '.[0].message')

scan_score=$(echo "$scan_result" | jq -r '.[0].score')

echo "Kubesec Scan Result:"
echo "$scan_result"

echo "Scan Score: $scan_score"

if [[ "$scan_score" -ge 10 ]]; then
    echo "Score is $scan_score"
    echo "Kubesec Scan Message: $scan_message"
else
    echo "Score is $scan_score, which is less than or equal to 10."
    echo "Scanning Kubernetes Resource has Failed"
    exit 1
fi
