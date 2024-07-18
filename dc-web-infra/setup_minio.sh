#!/bin/bash

# Check if required environment variables are set
if [ -z "$MINIO_ENDPOINT" ] || [ -z "$MINIO_ROOT_USER" ] || [ -z "$MINIO_ROOT_PASSWORD" ] || [ -z "$APP_USER" ] || [ -z "$APP_USER_PASSWORD" ] || [ -z "$S3_BUCKET_NAME" ]; then
    echo "Error: Required environment variables are not set."
    echo "Please set MINIO_ENDPOINT, MINIO_ROOT_USER, MINIO_ROOT_PASSWORD, APP_USER, APP_USER_PASSWORD, and S3_BUCKET_NAME."
    exit 1
fi

# Set up MinIO client alias with root credentials
mc alias set myminio $MINIO_ENDPOINT $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

# Create bucket if it doesn't exist
if ! mc ls myminio/$S3_BUCKET_NAME > /dev/null 2>&1; then
    mc mb myminio/$S3_BUCKET_NAME
    echo "Bucket $S3_BUCKET_NAME created successfully."
else
    echo "Bucket $S3_BUCKET_NAME already exists."
fi

# Create app-user if it doesn't exist
if ! mc admin user info myminio $APP_USER > /dev/null 2>&1; then
    mc admin user add myminio $APP_USER $APP_USER_PASSWORD
    echo "User $APP_USER created successfully."
else
    echo "User $APP_USER already exists."
fi

# Create policy for app-user
cat > app-user-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::$S3_BUCKET_NAME",
                "arn:aws:s3:::$S3_BUCKET_NAME/*"
            ]
        }
    ]
}
EOF

# Remove existing policy if it exists, then create new policy
mc admin policy remove myminio app-user-policy > /dev/null 2>&1
mc admin policy create myminio app-user-policy app-user-policy.json

# Attach policy to app-user
mc admin policy attach myminio app-user-policy --user $APP_USER

echo "MinIO initial setup completed successfully!"
echo "Bucket: $S3_BUCKET_NAME"
echo "User: $APP_USER"
echo "Policy: app-user-policy"