#!/bin/bash

BUCKET_NAME="java-devsecops-tf-state"
REGION="ap-southeast-1"

create_resources() {
  # s3 bucket
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"

  aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

  echo "Resources created successfully!"
}

delete_resources() {
  # s3 bucket
  aws s3api list-object-versions --bucket "$BUCKET_NAME" \
    --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output=json \
    | aws s3api delete-objects --bucket "$BUCKET_NAME" --delete file:///dev/stdin

  aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$REGION"

  echo "Resources deleted successfully!"
}

echo "Choose an option:"
echo "1) Create backend resources"
echo "2) Delete backend resources"
read -rp "Enter your choice [1 or 2]: " choice

case "$choice" in
  1) create_resources ;;
  2) delete_resources ;;
  *) echo "Invalid option. Exiting." ;;
esac