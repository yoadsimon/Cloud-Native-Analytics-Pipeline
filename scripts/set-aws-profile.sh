#!/bin/bash

# Set AWS profile for Cloud Native Analytics Pipeline project
export AWS_PROFILE=cloud-native-analytics

echo "🔧 Setting AWS Profile for Cloud Native Analytics Pipeline"
echo "✅ AWS Profile set to: $AWS_PROFILE"
echo ""
echo "🔍 Verifying account info:"
if aws sts get-caller-identity --profile $AWS_PROFILE 2>/dev/null; then
    echo ""
    echo "📦 S3 buckets in this account:"
    aws s3 ls --profile $AWS_PROFILE
    echo ""
    echo "✅ SUCCESS: Using personal AWS account for this project"
    echo "💡 To use this profile in your current shell, run:"
    echo "   source scripts/set-aws-profile.sh"
else
    echo "❌ ERROR: Profile verification failed"
    echo "💡 Check your AWS credentials for profile: $AWS_PROFILE"
fi 