# Cloud-Native Analytics Pipeline on Public Data

## 📌 Project Overview

**Title:** Cloud-Native Analytics Pipeline on Public Data

**Goal:** Build an end-to-end data pipeline that ingests a public dataset, processes and transforms it with PySpark on AWS Glue, stores intermediate and final data in Parquet format on S3, and loads curated tables into Amazon Redshift for analytics.

**Why:**
- Gain hands-on experience with Spark in the cloud
- Learn Glue's serverless ETL orchestration & Data Catalog
- Master Parquet's columnar storage benefits
- Practice loading, modeling, and querying data in Redshift

## 🎯 Success Criteria & KPIs

| KPI | Target |
|-----|--------|
| Pipeline end-to-end runtime | < 15 minutes per daily run |
| Data freshness SLA | < 10 minutes between raw arrival and Redshift availability |
| Data volume processed | ~1–2 GB/day (simulate growth) |
| Query performance on Redshift | Average response < 500 ms for key analytics queries |
| Resource usage / cost efficiency | Glue job cost < $5/month on free-tier usage |

## 🗺️ High-Level Milestones

- [x] Environment & Baseline Setup
- [x] Raw Data Ingestion
- [x] PySpark Transformations
- [x] Glue Orchestration & Catalog
- [ ] Parquet Storage Layers in S3
- [ ] Redshift Cluster & Table Design
- [ ] Data Loading into Redshift
- [ ] Analytics & Validation
- [ ] Monitoring, Alerts & Cost Control
- [ ] Documentation & Demo Dashboard

## 🔨 Detailed Step-by-Step Plan

### 1. Environment & Baseline Setup
- [x] 1.1 Create a new AWS account (or use existing with free-tier)
- [x] 1.2 Install and configure Terraform
- [x] 1.3 Create Infrastructure as Code (Terraform) configurations for:
  - [x] S3 bucket with proper folder structure and lifecycle policies
  - [x] IAM roles and policies for Glue ETL jobs
  - [x] IAM roles for Redshift cluster access
  - [x] Service-linked roles with least-privilege access
- [x] 1.4 Install/configure AWS CLI locally
- [x] 1.5 Install Apache Spark locally (or use Databricks Community) for initial dev
- [x] 1.6 Deploy infrastructure using `terraform apply`

### 2. Raw Data Ingestion ✅
- [x] 2.1 Select a public dataset (NYC Taxi Trip Data from TLC)
- [x] 2.2 Download a sample snapshot (48MB, 3M records, February 2024)
- [x] 2.3 Upload initial snapshot to `s3://bucket/raw/dataset=nyc_taxi/year=2024/month=02/`
- [x] 2.4 Draft a Python script to automate data ingestion (`scripts/ingest_nyc_taxi_data.py`)
- [x] 2.5 Test raw data accessibility (S3 ls verified, partitioned structure working)

### 3. PySpark Transformations (Local → S3) ✅
- [x] 3.1 Develop a PySpark job locally to:
  - [x] Read Parquet from `s3://…/raw/` (3M records, 48MB)
  - [x] Apply comprehensive cleaning (nulls, data quality rules, validation)
  - [x] Enrich with derived columns (time categories, business metrics, quality flags)
  - [x] Write partitioned Parquet to `s3://…/staging/` (by date & time_of_day)
- [x] 3.2 Benchmark local job: 2.96M clean records, 30-second runtime, enterprise-grade transformations
- [x] 3.3 Parameterized job with configurable paths and comprehensive business logic

### 4. AWS Glue Orchestration & Data Catalog ✅
- [x] 4.1 Created Glue Crawlers for raw and staging data discovery
  - [x] Raw crawler: `cloud-native-analytics-raw-crawler`
  - [x] Staging crawler: `cloud-native-analytics-staging-crawler`
  - [x] Glue database: `cloud-native-analytics-analytics-db`
- [x] 4.2 Created production Glue ETL Job:
  - [x] Job name: `cloud-native-analytics-nyc-taxi-etl`
  - [x] Glue 4.0 runtime with PySpark optimizations
  - [x] 2 G.1X workers for cost-effective processing
  - [x] Comprehensive job parameters and CloudWatch logging
- [x] 4.3 Deployed serverless ETL infrastructure with Terraform
- [x] 4.4 Created automated triggers:
  - [x] Daily scheduled trigger (6 AM UTC, disabled for testing)
  - [x] Conditional trigger to run staging crawler after ETL success

### 5. Parquet Storage Layers in S3
- [ ] 5.1 Confirm that Parquet in `/staging/` uses partitioning (e.g. by date/hour)
- [ ] 5.2 Implement a second Glue job or step in the same job to:
  - [ ] Read from `/staging/`
  - [ ] Perform additional aggregations (e.g. daily summaries)
  - [ ] Write final Parquet tables to `/curated/`
- [ ] 5.3 Use the Glue Crawler to register curated tables as well

### 6. Amazon Redshift Cluster & Table Design
- [ ] 6.1 Launch a small Redshift Serverless endpoint (or smallest RA3 node)
- [ ] 6.2 Define database, schema and IAM role for COPY
- [ ] 6.3 Design star schema:
  - [ ] Fact Table: e.g. trips (with measures: count, total_fare)
  - [ ] Dimension Tables: time_dim, location_dim, vendor_dim
- [ ] 6.4 Create DDL scripts for each table (with appropriate sort/dist keys)

### 7. Data Loading into Redshift
- [ ] 7.1 Grant Redshift access to S3 via an IAM role
- [ ] 7.2 Write COPY commands to load Parquet from `s3://…/curated/` into each table
- [ ] 7.3 Execute initial load and validate row counts vs. Parquet metadata
- [ ] 7.4 Automate incremental loads (e.g. only new partitions) via Glue job or Airflow

### 8. Analytics & Validation
- [ ] 8.1 Craft key analytic queries:
  - [ ] Daily total metrics
  - [ ] Top N locations by volume
  - [ ] Time-series trends
- [ ] 8.2 Measure query runtimes—tune sort & distribution keys as needed
- [ ] 8.3 Validate data integrity between Parquet and Redshift via cross-table joins

### 9. Monitoring, Alerts & Cost Control
- [ ] 9.1 Enable CloudWatch metrics for Glue job durations and error counts
- [ ] 9.2 Configure alarms for job failures or runtime > KPI threshold
- [ ] 9.3 Set AWS Budget alerts to notify you if spend approaches free-tier limits
- [ ] 9.4 Tear down or pause Redshift when idle (via a Lambda script or manually)

### 10. Documentation & Demo Dashboard
- [ ] 10.1 Write a README that describes architecture, data flow, and how to run each step
- [ ] 10.2 Capture diagrams (draw.io or Markdown ASCII) showing the pipeline
- [ ] 10.3 Build a lightweight dashboard (Streamlit or Retool free tier) pointing at Redshift to surface 3–5 key insights
- [ ] 10.4 Record a short screencast demo walking through data landing in S3 → Glue → Redshift → Dashboard

## 🎓 What You'll Have by the End

- ✅ Production-style ETL pipeline deploying PySpark on AWS Glue
- ✅ Familiarity with Parquet partitioning and performance tuning
- ✅ Hands-on Redshift data loading, schema design, and query optimization
- ✅ End-to-end orchestration, monitoring, and cost-aware operations
- ✅ A polished demo you can showcase in interviews

## 📁 Project Structure

```
Cloud-Native-Analytics-Pipeline/
├── README.md                     # This file
├── docs/                        # Documentation and diagrams
├── scripts/                     # Data ingestion and utility scripts
├── spark/                       # PySpark jobs
├── sql/                         # DDL scripts for Redshift
├── glue/                        # AWS Glue job configurations
├── monitoring/                  # CloudWatch and alerting configs
├── dashboard/                   # Dashboard code (Streamlit/Retool)
└── requirements.txt             # Python dependencies
```

## 🚀 Getting Started

1. Clone this repository
2. **Set up AWS Profile**: Run `source scripts/set-aws-profile.sh` to use the correct AWS account
3. Review the project plan above
4. Start with **Step 1: Environment & Baseline Setup**
5. Check off each task as you complete it
6. Document any issues or learnings in the relevant folders

### ⚠️ AWS Profile Warning
This project uses a **personal AWS account** (profile: `cloud-native-analytics`), not your work AWS account. Always verify you're using the correct profile before running AWS commands.

## 📝 Notes & Learnings

_Add your notes, challenges, and key learnings here as you progress through the project_

---

**Good luck with your Similarweb interview preparation!** 🚀 