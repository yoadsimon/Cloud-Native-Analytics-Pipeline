# Cloud-Native Analytics Pipeline Deployment Guide

## 🚀 Quick Start

This guide walks you through deploying the complete Cloud-Native Analytics Pipeline from scratch. Perfect for demonstrating the project in interviews or setting up your own analytics infrastructure.

## 📋 Prerequisites

### **Required Tools**
- **AWS CLI** v2.x with configured credentials
- **Terraform** v1.5+ 
- **Python** 3.8+ with pip
- **Git** for version control
- **jq** for JSON processing (monitoring scripts)
- **psql** for database connectivity testing

### **AWS Account Setup**
- AWS account with admin or sufficient IAM permissions
- AWS CLI configured with appropriate profile
- Ensure you're using the **correct AWS account** (not work account!)

### **Cost Considerations**
- **Estimated Monthly Cost**: $10-30 (with cleanup)
- **Budget Alerts**: Set at $50 monthly, $5 daily
- **Resource Management**: Use serverless services for cost optimization

## 🗂️ Project Structure

```
Cloud-Native-Analytics-Pipeline/
├── terraform/              # Infrastructure as Code
│   ├── main.tf             # Core infrastructure
│   ├── s3.tf              # Data lake setup
│   ├── glue.tf            # ETL jobs
│   ├── redshift.tf        # Analytics warehouse
│   ├── monitoring.tf      # CloudWatch, SNS
│   └── budget.tf          # Cost controls
├── scripts/               # Data processing & utilities
├── sql/                   # Analytics queries
├── dashboard/             # Streamlit BI dashboard
└── docs/                  # Documentation
```

## 🎯 Step-by-Step Deployment

### **Step 1: Clone & Setup**

```bash
# Clone the repository
git clone <repository-url>
cd Cloud-Native-Analytics-Pipeline

# Verify AWS CLI configuration
aws sts get-caller-identity

# Set the correct AWS profile (if needed)
export AWS_PROFILE=cloud-native-analytics
```

### **Step 2: Deploy Core Infrastructure**

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy infrastructure (takes ~5-10 minutes)
terraform apply

# Save important outputs
terraform output > ../deployment_outputs.txt
```

**Expected Resources Created:**
- S3 bucket for data lake
- IAM roles and policies
- Glue database and jobs
- Redshift Serverless namespace/workgroup
- CloudWatch monitoring infrastructure
- SNS topic for alerts
- AWS Budgets for cost control

### **Step 3: Upload Sample Data**

```bash
cd ..

# Download NYC Taxi sample data (if not already present)
# Data is included in the repository

# Upload to S3 raw layer
python scripts/ingest_nyc_taxi_data.py

# Verify upload
aws s3 ls s3://$(terraform -chdir=terraform output -raw s3_bucket_name)/raw/ --recursive
```

### **Step 4: Run ETL Pipeline**

```bash
# Run the primary ETL job (raw → staging)
aws glue start-job-run --job-name cloud-native-analytics-nyc-taxi-etl

# Monitor job progress
aws glue get-job-runs --job-name cloud-native-analytics-nyc-taxi-etl --max-results 1

# After ETL completes, run aggregation job (staging → curated)
aws glue start-job-run --job-name cloud-native-analytics-curated-aggregations

# Monitor aggregation progress
aws glue get-job-runs --job-name cloud-native-analytics-curated-aggregations --max-results 1
```

**Expected Processing Times:**
- ETL Job: ~3-4 minutes
- Aggregation Job: ~2-3 minutes
- Total Pipeline: ~6-7 minutes

### **Step 5: Validate Data Pipeline**

```bash
# Run quick health check
chmod +x scripts/quick_health_check.sh
./scripts/quick_health_check.sh

# Check S3 data structure
aws s3 ls s3://$(terraform -chdir=terraform output -raw s3_bucket_name)/ --recursive | head -20

# Verify Glue Data Catalog
aws glue get-tables --database-name cloud-native-analytics-analytics-db
```

### **Step 6: Setup Redshift Analytics**

```bash
# Get Redshift endpoint
terraform -chdir=terraform output redshift_endpoint

# Connect and create external schema (run from Redshift Query Editor)
psql -h <redshift-endpoint> -U admin -d analytics_db -p 5439

# Or use AWS Console Query Editor v2
# Navigate to: https://console.aws.amazon.com/sqlworkbench/home
```

**Execute in Redshift:**
```sql
-- Create external schema for Glue curated data
CREATE EXTERNAL SCHEMA glue_curated
FROM DATA CATALOG
DATABASE 'cloud-native-analytics-analytics-db'
IAM_ROLE 'arn:aws:iam::ACCOUNT:role/cloud-native-analytics-redshift-role';

-- Verify tables are accessible
SELECT * FROM SVV_EXTERNAL_TABLES WHERE schemaname = 'glue_curated';

-- Test analytics query
SELECT COUNT(*) FROM glue_curated.daily_metrics;
```

### **Step 7: Launch Dashboard**

```bash
cd dashboard

# Make startup script executable
chmod +x run_dashboard.sh

# Launch dashboard (installs dependencies automatically)
./run_dashboard.sh
```

**Dashboard Access:**
- **URL**: http://localhost:8501
- **Features**: Real-time Redshift connectivity, interactive charts, KPIs
- **Data**: Live data from your pipeline

### **Step 8: Configure Monitoring**

```bash
# Set up email alerts (update email in terraform/variables.tf)
terraform -chdir=terraform apply -var="alert_email=your-email@example.com"

# Confirm SNS subscription in your email
# Check AWS Console for budget alerts setup
```

**Monitoring Endpoints:**
- **CloudWatch Dashboard**: [Console Link](https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:)
- **Budget Alerts**: [Console Link](https://console.aws.amazon.com/billing/home#/budgets)
- **SNS Topics**: [Console Link](https://console.aws.amazon.com/sns/v3/home?region=us-east-1#/topics)

## 🔍 Verification Checklist

### **Infrastructure Validation**
- [ ] S3 bucket created with proper folder structure
- [ ] Glue jobs deployed and executable
- [ ] Redshift Serverless workgroup available
- [ ] IAM roles configured with proper permissions
- [ ] CloudWatch alarms and dashboard created
- [ ] SNS topic configured for alerts
- [ ] Budget alerts configured

### **Data Pipeline Validation**
- [ ] Raw data uploaded to S3 (48MB, 3M records)
- [ ] ETL job completed successfully (546 staging files)
- [ ] Aggregation job created 5 curated tables
- [ ] Glue Data Catalog populated with schema
- [ ] Redshift Spectrum can query external tables
- [ ] 8.38M records accessible in analytics layer

### **Dashboard Validation**
- [ ] Streamlit dashboard launches successfully
- [ ] Database connection established
- [ ] KPIs display correctly
- [ ] Charts render with real data
- [ ] Data tables populate
- [ ] Refresh functionality works

### **Monitoring Validation**
- [ ] Health check script runs successfully
- [ ] CloudWatch metrics are being collected
- [ ] Alarms are in OK state
- [ ] Email subscription confirmed
- [ ] Budget tracking is active

## 🎨 Customization Options

### **Data Sources**
```bash
# To use your own dataset:
# 1. Upload to S3 raw layer
# 2. Modify Glue job scripts
# 3. Update schema in Data Catalog
# 4. Adjust dashboard queries
```

### **Scaling Configuration**
```hcl
# In terraform/glue.tf
default_arguments = {
  "--number-of-workers" = "5"  # Scale from 2 to 10
  "--worker-type"       = "G.1X"  # Or G.2X for more memory
}
```

### **Cost Optimization**
```hcl
# In terraform/budget.tf
limit_amount = "25"  # Reduce from $50 to $25
```

### **Dashboard Customization**
```python
# In dashboard/config.py
DASHBOARD_CONFIG = {
    'title': 'Your Custom Dashboard',
    'theme': 'dark'  # Change theme
}
```

## 🛠️ Troubleshooting

### **Common Issues**

**Issue**: Terraform fails with permissions error
```bash
# Solution: Check AWS CLI configuration
aws sts get-caller-identity
aws configure list-profiles
```

**Issue**: Glue job fails with S3 access error
```bash
# Solution: Verify IAM role permissions
aws iam get-role --role-name cloud-native-analytics-glue-etl-role
```

**Issue**: Redshift connection fails
```bash
# Solution: Check security group and endpoint
terraform -chdir=terraform output redshift_endpoint
aws redshift-serverless get-workgroup --workgroup-name cloud-native-analytics-workgroup
```

**Issue**: Dashboard can't connect to Redshift
```bash
# Solution: Update dashboard/.env with correct password
cp dashboard/env_example.txt dashboard/.env
# Edit dashboard/.env with REDSHIFT_PASSWORD=TempPassword123!
```

### **Diagnostic Commands**

```bash
# Check AWS resource status
./scripts/quick_health_check.sh

# Validate Terraform state
terraform -chdir=terraform state list

# Check Glue job logs
aws logs describe-log-groups --log-group-name-prefix "/aws-glue"

# Test Redshift connectivity
psql -h $(terraform -chdir=terraform output -raw redshift_endpoint | jq -r '.[0].address') \
     -U admin -d analytics_db -p 5439 -c "SELECT 1;"
```

## 🧹 Cleanup Instructions

### **Temporary Cleanup (Keep Infrastructure)**
```bash
# Pause Redshift Serverless (manual in console)
# Stop Streamlit dashboard (Ctrl+C)
# No action needed for S3/Glue (serverless, pay-per-use)
```

### **Full Cleanup (Remove All Resources)**
```bash
# WARNING: This will delete all data and infrastructure
cd terraform
terraform destroy

# Verify cleanup
aws s3 ls | grep cloud-native-analytics
aws glue get-databases
aws redshift-serverless list-workgroups
```

## 📊 Performance Benchmarks

### **Expected Performance**
- **Infrastructure Deployment**: 5-10 minutes
- **Data Upload**: 30 seconds (48MB)
- **ETL Processing**: 3-4 minutes (3M records)
- **Aggregation**: 2-3 minutes (5 tables)
- **Dashboard Startup**: 10-15 seconds
- **Query Response**: <1 second

### **Resource Utilization**
- **S3 Storage**: ~150MB total (raw + staging + curated)
- **Glue Compute**: 2 G.1X workers (auto-scaling)
- **Redshift**: 32 RPU base capacity
- **Network**: Minimal inter-service traffic

## 🎓 Interview Demo Script

### **5-Minute Demo Flow**
1. **Architecture Overview** (1 min): Show docs/ARCHITECTURE.md
2. **Infrastructure** (1 min): Terraform resources, AWS Console
3. **Data Pipeline** (1 min): S3 → Glue → Redshift flow
4. **Analytics Dashboard** (1 min): Live Streamlit demo
5. **Monitoring** (1 min): CloudWatch, alerts, budgets

### **Key Talking Points**
- **Scale**: 3M records, sub-second queries
- **Architecture**: Cloud-native, serverless-first
- **Operations**: Comprehensive monitoring, cost controls
- **Performance**: Optimized partitioning, columnar storage
- **Security**: IAM roles, least privilege access

---

**🚀 You now have a production-ready, enterprise-grade analytics pipeline!**

Perfect for showcasing modern data engineering skills in interviews and demonstrating cloud-native best practices. 