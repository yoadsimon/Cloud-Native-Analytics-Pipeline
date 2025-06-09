#!/bin/bash
# Download Analytics Results from S3
# Run this after executing the UNLOAD commands in Redshift

# Set AWS profile
export AWS_PROFILE=cloud-native-analytics

# Create local results directory
mkdir -p analytics-results

echo "📊 Downloading Analytics Results from S3..."

# Download all analytics results files
aws s3 sync s3://cloud-native-analytics-pipeline-d8e6ca17/analytics-results/ ./analytics-results/ \
    --exclude "*" \
    --include "*.csv" \
    --profile cloud-native-analytics

echo "✅ Analytics results downloaded to ./analytics-results/"

# List downloaded files
echo "📁 Downloaded files:"
ls -la ./analytics-results/

echo ""
echo "🎯 You can now:"
echo "   • Open CSV files in Excel for analysis"
echo "   • Import into Python/R for advanced analytics"
echo "   • Use for dashboard creation"
echo "   • Share results with stakeholders" 