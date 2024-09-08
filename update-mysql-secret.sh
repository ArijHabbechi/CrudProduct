#!/bin/bash

cd Spring
# Load .env file
set -o allexport
source .env
set -o allexport

# Encode values to base64
MYSQL_ROOT_PASSWORD_BASE64=$(echo -n "$MYSQL_ROOT_PASSWORD" | base64)
MYSQL_DATABASE_BASE64=$(echo -n "$MYSQL_DATABASE" | base64)
MYSQL_USER_BASE64=$(echo -n "$MYSQL_USER" | base64)
MYSQL_PASSWORD_BASE64=$(echo -n "$MYSQL_PASSWORD" | base64)


cd ..
# Update the existing mysql-secret.yaml file
sed -i "s|\(MYSQL_ROOT_PASSWORD:\s*\).*|\1$MYSQL_ROOT_PASSWORD_BASE64|" mysql-secret.yml
sed -i "s|\(MYSQL_DATABASE:\s*\).*|\1$MYSQL_DATABASE_BASE64|" mysql-secret.yml
sed -i "s|\(MYSQL_USER:\s*\).*|\1$MYSQL_USER_BASE64|" mysql-secret.yml
sed -i "s|\(MYSQL_PASSWORD:\s*\).*|\1$MYSQL_PASSWORD_BASE64|" mysql-secret.yml

echo "mysql-secret.yaml has been updated with the base64 encoded values."

