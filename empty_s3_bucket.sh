#!/bin/bash

BUCKET_NAME="myappalb.logs77399957"

echo "Emptying bucket $BUCKET_NAME"
aws s3 rm s3://$BUCKET_NAME --recursive
aws s3api delete-objects --bucket $BUCKET_NAME --delete "$(aws s3api list-object-versions --bucket $BUCKET_NAME --output=json --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
aws s3api delete-objects --bucket $BUCKET_NAME --delete "$(aws s3api list-object-versions --bucket $BUCKET_NAME --output=json --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"
echo "Bucket emptying process completed"