#!/bin/bash

# Check if required environment variables are set
if [ -z "$MINIO_ENDPOINT" ] || [ -z "$MINIO_ROOT_USER" ] || [ -z "$MINIO_ROOT_PASSWORD" ] || [ -z "$APP_USER" ]; then
    echo "Error: Required environment variables are not set."
    echo "Please set MINIO_ENDPOINT, MINIO_ROOT_USER, MINIO_ROOT_PASSWORD, and APP_USER."
    exit 1
fi

# Set up MinIO client alias with root credentials
mc alias set myminio $MINIO_ENDPOINT $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

# Generate new access key for app-user
KEY_PAIR=$(mc admin user svcacct add myminio $APP_USER)

# Parse KEY_PAIR output
ACCESS_KEY=""
SECRET_KEY=""
while IFS= read -r line; do
    case "$line" in
        *"Access Key:"*) ACCESS_KEY="${line#*Access Key: }";;
        *"Secret Key:"*) SECRET_KEY="${line#*Secret Key: }";;
    esac
done <<< "$KEY_PAIR"

echo "Access key generated successfully!"
echo "AWS_ACCESS_KEY_ID=$ACCESS_KEY"
echo "AWS_SECRET_ACCESS_KEY=$SECRET_KEY"
echo "Please save these credentials securely."