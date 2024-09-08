#!/bin/bash

# Grant full permissions to the current directory
chmod 777 $(pwd)

# Run the OWASP ZAP Docker container to scan the specified API
docker run -u root -v $(pwd):/zap/wrk/:rw -t zaproxy/zap-stable zap-api-scan.py \
    -t http://192.168.49.2:$NODE_PORT/SpringMVC/v3/api-docs \
    -f openapi \
    -r zap_report.html

# Capture the exit code of the last command
exit_code=$?

# Output the exit code
echo "Exit Code : $exit_code"

# Check if there was a risk detected based on the exit code
if [[ $exit_code -ne 0 ]]; then
    echo "OWASP ZAP Report has either Low/Medium/High Risk. Please check the HTML Report"
    exit 1
else
    echo "OWASP ZAP did not report any Risk"
fi
