#!/usr/bin/env bash
set -euo pipefail

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=${1:-us-east-1}
BUCKET="config-logs-${ACCOUNT_ID}-${REGION}"

aws s3 mb s3://$BUCKET 2>/dev/null || true

aws iam create-role --role-name AWSConfigRole \
  --assume-role-policy-document '{
    "Version":"2012-10-17","Statement":[{
      "Effect":"Allow","Principal":{"Service":"config.amazonaws.com"},"Action":"sts:AssumeRole"
    }]}'
aws iam attach-role-policy --role-name AWSConfigRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSConfigRole || true

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/AWSConfigRole"

aws configservice put-configuration-recorder \
  --configuration-recorder "name=default,roleARN=${ROLE_ARN},recordingGroup={allSupported=true,includeGlobalResourceTypes=true}"

aws configservice put-delivery-channel \
  --delivery-channel "name=default,s3BucketName=${BUCKET}"

aws configservice start-configuration-recorder --configuration-recorder-name default

aws securityhub enable-security-hub --region $REGION

aws securityhub batch-enable-standards --standards-subscription-requests \
 '[{"StandardsArn":"arn:aws:securityhub:::standards/aws-foundational-security-best-practices/v/1.0.0"},
   {"StandardsArn":"arn:aws:securityhub:::standards/cis-aws-foundations-benchmark/v/1.4.0"}]' \
 --region $REGION

echo "Config + SecurityHub enabled in $REGION"

