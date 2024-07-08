#!/bin/bash
# Script to check MySQL connectivity

while ! mysqladmin ping -h"db" --silent; do
    echo "Waiting for MySQL to be up..."
    sleep 2
done

# Start the Spring application
exec "$@"
