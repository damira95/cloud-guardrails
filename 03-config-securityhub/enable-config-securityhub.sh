#!/bin/bash
set -euo pipefail

REGION="us-east-1”
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

CONFIG_RECORDER_FILE=/tmp/config-recorder.json
DELIVERY_CHANNEL_FILE=/tmp/delivery-channel.json
STANDARDS_FILE=/tmp/securityhub-standards.json

cat > "$CONFIG_RECORDER_FILE" <<EOF
{
  "name": "default",
  "roleARN": "arn:aws:iam::$ACCOUNT_ID:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig",
  "recordingGroup": {
    "allSupported": true,
    "includeGlobalResourceTypes": true
  }
}
EOF

cat > "$DELIVERY_CHANNEL_FILE" <<EOF
{
  "name": "default",
  "s3BucketName": "config-logs-$ACCOUNT_ID"
}
EOF

cat > "$STANDARDS_FILE" <<EOF
[
  {
    "StandardsArn": "arn:aws:securityhub:$REGION:$ACCOUNT_ID:standard/aws-foundational-security-best-practices/v/1.0.0"
  },
  {
    "StandardsArn": "arn:aws:securityhub:$REGION:$ACCOUNT_ID:standard/cis-aws-foundations-benchmark/v/1.2.0"
  }
]
EOF

echo "=== Enabling AWS Config in $REGION for account $ACCOUNT_ID ==="
aws configservice put-configuration-recorder --configuration-recorder file://"$CONFIG_RECORDER_FILE"
aws configservice put-delivery-channel --delivery-channel file://"$DELIVERY_CHANNEL_FILE"
aws configservice start-configuration-recorder --configuration-recorder-name default
echo "=== AWS Config Enabled ==="

echo "=== Enabling Security Hub in $REGION ==="
aws securityhub enable-security-hub --region "$REGION" || echo "Security Hub already enabled"
aws securityhub batch-enable-standards --region "$REGION" \
  --standards-subscription-requests file://"$STANDARDS_FILE"
echo "=== DONE ==="
