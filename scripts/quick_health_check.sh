#!/bin/bash

# Quick Health Check Script for Cloud-Native Analytics Pipeline
# Provides fast status overview of all pipeline components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGION="us-east-1"
PROJECT_NAME="cloud-native-analytics-pipeline"
WORKGROUP_NAME="cloud-native-analytics-workgroup"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  PIPELINE QUICK HEALTH CHECK${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Function to check AWS CLI
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI not found${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ AWS CLI available${NC}"
}

# Function to check Glue job status
check_glue_job() {
    local job_name=$1
    echo -n "Checking Glue job: $job_name... "
    
    # Get the latest job run
    latest_run=$(aws glue get-job-runs \
        --job-name "$job_name" \
        --max-results 1 \
        --region "$REGION" \
        --query 'JobRuns[0].{State:JobRunState,StartedOn:StartedOn,ExecutionTime:ExecutionTime}' \
        --output json 2>/dev/null || echo '{}')
    
    if [[ "$latest_run" == "{}" ]]; then
        echo -e "${YELLOW}⚠️  No runs found${NC}"
        return
    fi
    
    state=$(echo "$latest_run" | jq -r '.State // "UNKNOWN"')
    execution_time=$(echo "$latest_run" | jq -r '.ExecutionTime // "N/A"')
    
    case "$state" in
        "SUCCEEDED")
            echo -e "${GREEN}✅ $state (${execution_time}s)${NC}"
            ;;
        "RUNNING")
            echo -e "${YELLOW}🔄 $state${NC}"
            ;;
        "FAILED"|"ERROR"|"TIMEOUT")
            echo -e "${RED}❌ $state${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️  $state${NC}"
            ;;
    esac
}

# Function to check Redshift workgroup
check_redshift_workgroup() {
    echo -n "Checking Redshift workgroup: $WORKGROUP_NAME... "
    
    workgroup_info=$(aws redshift-serverless get-workgroup \
        --workgroup-name "$WORKGROUP_NAME" \
        --region "$REGION" \
        --query 'workgroup.{Status:status,BaseCapacity:baseCapacity}' \
        --output json 2>/dev/null || echo '{}')
    
    if [[ "$workgroup_info" == "{}" ]]; then
        echo -e "${RED}❌ Not found${NC}"
        return
    fi
    
    status=$(echo "$workgroup_info" | jq -r '.Status // "UNKNOWN"')
    capacity=$(echo "$workgroup_info" | jq -r '.BaseCapacity // "N/A"')
    
    case "$status" in
        "AVAILABLE")
            echo -e "${GREEN}✅ $status (${capacity} RPU)${NC}"
            ;;
        "CREATING"|"MODIFYING")
            echo -e "${YELLOW}🔄 $status${NC}"
            ;;
        *)
            echo -e "${RED}❌ $status${NC}"
            ;;
    esac
}

# Function to check S3 bucket
check_s3_bucket() {
    echo -n "Checking S3 bucket access... "
    
    # Get bucket name from Terraform state or use pattern
    bucket_name=$(aws s3 ls | grep "cloud-native-analytics-pipeline" | awk '{print $3}' | head -1)
    
    if [[ -z "$bucket_name" ]]; then
        echo -e "${YELLOW}⚠️  Bucket not found${NC}"
        return
    fi
    
    # Check if we can access the bucket
    if aws s3 ls "s3://$bucket_name" >/dev/null 2>&1; then
        object_count=$(aws s3 ls "s3://$bucket_name" --recursive | wc -l)
        echo -e "${GREEN}✅ Accessible ($object_count objects)${NC}"
    else
        echo -e "${RED}❌ Access denied${NC}"
    fi
}

# Function to check recent CloudWatch alarms
check_cloudwatch_alarms() {
    echo -n "Checking CloudWatch alarms... "
    
    alarm_states=$(aws cloudwatch describe-alarms \
        --alarm-name-prefix "$PROJECT_NAME" \
        --region "$REGION" \
        --query 'MetricAlarms[].{Name:AlarmName,State:StateValue}' \
        --output json 2>/dev/null || echo '[]')
    
    if [[ "$alarm_states" == "[]" ]]; then
        echo -e "${YELLOW}⚠️  No alarms configured${NC}"
        return
    fi
    
    alarm_count=$(echo "$alarm_states" | jq length)
    in_alarm=$(echo "$alarm_states" | jq -r '.[] | select(.State == "ALARM") | .Name' | wc -l)
    
    if [[ $in_alarm -eq 0 ]]; then
        echo -e "${GREEN}✅ All alarms OK ($alarm_count total)${NC}"
    else
        echo -e "${RED}❌ $in_alarm alarms in ALARM state${NC}"
        echo "$alarm_states" | jq -r '.[] | select(.State == "ALARM") | "  - " + .Name'
    fi
}

# Function to get cost estimate
check_recent_costs() {
    echo -n "Checking recent costs... "
    
    # Get costs for the last 7 days (macOS compatible)
    end_date=$(date +%Y-%m-%d)
    start_date=$(date -v-7d +%Y-%m-%d)
    
    cost_data=$(aws ce get-cost-and-usage \
        --time-period Start="$start_date",End="$end_date" \
        --granularity DAILY \
        --metrics BlendedCost \
        --region us-east-1 \
        --query 'ResultsByTime[].Total.BlendedCost.Amount' \
        --output json 2>/dev/null || echo '[]')
    
    if [[ "$cost_data" == "[]" ]]; then
        echo -e "${YELLOW}⚠️  Cost data unavailable${NC}"
        return
    fi
    
    total_cost=$(echo "$cost_data" | jq -r 'map(tonumber) | add')
    
    if (( $(echo "$total_cost > 0" | bc -l) )); then
        echo -e "${GREEN}✅ \$$(printf "%.2f" "$total_cost") (7 days)${NC}"
    else
        echo -e "${GREEN}✅ \$0.00 (7 days)${NC}"
    fi
}

# Main execution
main() {
    check_aws_cli
    echo ""
    
    echo "Infrastructure Status:"
    echo "--------------------"
    check_s3_bucket
    check_redshift_workgroup
    echo ""
    
    echo "ETL Job Status:"
    echo "---------------"
    check_glue_job "cloud-native-analytics-pipeline-nyc-taxi-etl"
    check_glue_job "cloud-native-analytics-pipeline-curated-aggregations"
    echo ""
    
    echo "Monitoring Status:"
    echo "------------------"
    check_cloudwatch_alarms
    check_recent_costs
    echo ""
    
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${GREEN}Health check completed!${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

# Run main function
main 