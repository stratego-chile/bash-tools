#!/bin/bash

command -v aws >/dev/null 2>&1 || { echo >&2 "AWS CLI is not installed.  Aborting."; exit 1; }

BUCKET_NAME="$1"

aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null || { echo "Bucket $BUCKET_NAME does not exist"; exit 1; }

OBJECT_KEYS=$(aws s3api list-objects --bucket "$BUCKET_NAME" --query 'Contents[].Key' --output yaml | grep -oP '^ *- \K.*')

while IFS= read -r file_name; do
  echo "Updating ACL for $file_name"
  aws s3api put-object-acl --bucket "$BUCKET_NAME" --key "$file_name" --acl public-read
done <<< "$OBJECT_KEYS"
