# Cloud-Native Analytics Pipeline Architecture

## 🏗️ System Architecture Overview

The Cloud-Native Analytics Pipeline is an enterprise-grade data engineering solution built on AWS, demonstrating modern data architecture patterns and best practices for scalable analytics.

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           CLOUD-NATIVE ANALYTICS PIPELINE                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │   RAW DATA  │    │  STAGING    │    │  CURATED    │    │ ANALYTICS   │      │
│  │   LAYER     │───▶│   LAYER     │───▶│   LAYER     │───▶│   LAYER     │      │
│  │             │    │             │    │             │    │             │      │
│  │ • 48MB Data │    │ • Cleaned   │    │ • 5 Business│    │ • Redshift  │      │
│  │ • 3M Records│    │ • Validated │    │   Tables    │    │   Serverless│      │
│  │ • NYC Taxi  │    │ • Enriched  │    │ • Aggregated│    │ • BI Ready  │      │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘      │
│         │                   │                   │                   │          │
│         ▼                   ▼                   ▼                   ▼          │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                           AWS S3 DATA LAKE                               │   │
│  │                                                                         │   │
│  │  /raw/          /staging/        /curated/         /logs/              │   │
│  │  └── dataset=   └── partitioned  └── daily_metrics └── glue_logs/      │   │
│  │      nyc_taxi/      by_date/         location_..                       │   │
│  │      └── year=      └── time_of      payment_..                        │   │
│  │          2024/          day/         distance_..                       │   │
│  │          └── month=                  time_series_..                    │   │
│  │              02/                     performance_..                    │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                    │                                           │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                        PROCESSING LAYER                                  │   │
│  │                                                                         │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                │   │
│  │  │ AWS GLUE    │    │ AWS GLUE    │    │ GLUE DATA   │                │   │
│  │  │ ETL JOB     │    │ AGGREGATION │    │ CATALOG     │                │   │
│  │  │             │    │ JOB         │    │             │                │   │
│  │  │ • PySpark   │    │ • Business  │    │ • Schema    │                │   │
│  │  │ • Data      │    │   Logic     │    │   Discovery │                │   │
│  │  │   Cleaning  │    │ • KPI Calc  │    │ • Metadata  │                │   │
│  │  │ • Validation│    │ • Curated   │    │ • Lineage   │                │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘                │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                    │                                           │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                      ANALYTICS LAYER                                     │   │
│  │                                                                         │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                │   │
│  │  │ REDSHIFT    │    │ REDSHIFT    │    │ BUSINESS    │                │   │
│  │  │ SERVERLESS  │    │ SPECTRUM    │    │ INTELLIGENCE│                │   │
│  │  │             │    │             │    │             │                │   │
│  │  │ • 32 RPU    │    │ • External  │    │ • Streamlit │                │   │
│  │  │ • Auto      │    │   Tables    │    │   Dashboard │                │   │
│  │  │   Scaling   │    │ • 8.38M     │    │ • Real-time │                │   │
│  │  │ • BI Ready  │    │   Records   │    │   Analytics │                │   │
│  └─────────────┘    └─────────────┘    └─────────────┘                │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                    │                                           │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                      MONITORING LAYER                                    │   │
│  │                                                                         │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                │   │
│  │  │ CLOUDWATCH  │    │ SNS ALERTS  │    │ AWS BUDGETS │                │   │
│  │  │             │    │             │    │             │                │   │
│  │  │ • Metrics   │    │ • Email     │    │ • Cost      │                │   │
│  │  │ • Alarms    │    │   Notify    │    │   Control   │                │   │
│  │  │ • Dashboard │    │ • Failure   │    │ • Spend     │                │   │
│  │  │ • Logs      │    │   Detection │    │   Alerts    │                │   │
│  └─────────────┘    └─────────────┘    └─────────────┘                │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🔧 Component Architecture

### **1. Data Ingestion Layer**
- **Source**: NYC Taxi Trip Data (TLC Public Dataset)
- **Volume**: 48MB, 3M records (February 2024)
- **Format**: Parquet (optimized for analytics)
- **Storage**: S3 with lifecycle policies

### **2. ETL Processing Layer**
- **Engine**: AWS Glue with PySpark
- **Jobs**: 
  - Primary ETL (raw → staging)
  - Aggregation ETL (staging → curated)
- **Runtime**: Glue 4.0, Python 3.10
- **Scaling**: 2 G.1X workers (cost-optimized)

### **3. Storage Layer (S3 Data Lake)**
```
s3://cloud-native-analytics-pipeline-{suffix}/
├── raw/                     # Landing zone
│   └── dataset=nyc_taxi/
│       └── year=2024/month=02/
├── staging/                 # Cleaned & validated data
│   └── partitioned by pickup_date/time_of_day_category/
├── curated/                 # Business-ready analytics tables
│   ├── daily_metrics/
│   ├── location_analytics/
│   ├── time_series_analysis/
│   ├── customer_behavior/
│   └── performance_summary/
├── scripts/                 # ETL job scripts
└── logs/                   # Processing logs
```

### **4. Analytics Layer**
- **Engine**: Amazon Redshift Serverless
- **Capacity**: 32 RPU base capacity
- **Access**: Redshift Spectrum (external tables)
- **Performance**: Sub-second query response
- **Integration**: Direct S3 access via Glue Data Catalog

### **5. Business Intelligence Layer**
- **Dashboard**: Streamlit web application
- **Visualizations**: Plotly interactive charts
- **KPIs**: Real-time business metrics
- **Connectivity**: Direct Redshift connection

### **6. Monitoring & Operations**
- **Metrics**: CloudWatch alarms and dashboards
- **Alerting**: SNS email notifications
- **Cost Control**: AWS Budgets with thresholds
- **Health Checks**: Automated monitoring scripts

## 🚀 Data Flow Architecture

### **Primary Data Pipeline**
```
[NYC Taxi Data] 
    ↓ (Manual Download)
[S3 Raw Layer]
    ↓ (Glue ETL Job - 3m 27s)
[S3 Staging Layer] (546 partitioned files)
    ↓ (Glue Aggregation Job - 2m 39s)
[S3 Curated Layer] (5 business tables)
    ↓ (Glue Data Catalog)
[Redshift Spectrum] (8.38M accessible records)
    ↓ (SQL Analytics)
[Streamlit Dashboard] (Real-time BI)
```

### **Monitoring Pipeline**
```
[Pipeline Components]
    ↓ (CloudWatch Metrics)
[Metric Alarms] 
    ↓ (Threshold Breaches)
[SNS Notifications]
    ↓ (Email Alerts)
[Operations Team]
```

## 🎯 Design Principles

### **1. Cloud-Native Architecture**
- **Serverless-first**: Glue, Redshift Serverless, Lambda
- **Managed services**: Minimize operational overhead
- **Auto-scaling**: Elastic compute based on demand
- **Pay-per-use**: Cost optimization through serverless

### **2. Data Lake Architecture**
- **Schema-on-read**: Flexible data structure evolution
- **Partitioning**: Optimized for query performance
- **Multiple formats**: Parquet for analytics, JSON for logs
- **Tiered storage**: Lifecycle policies for cost optimization

### **3. Modern ETL Patterns**
- **ELT over ETL**: Load first, transform in analytics layer
- **Immutable data**: Append-only with versioning
- **Idempotent processing**: Rerunnable without side effects
- **Data lineage**: Full traceability through Glue Catalog

### **4. Performance Optimization**
- **Columnar storage**: Parquet for fast aggregations
- **Partitioning strategy**: Date/time-based for time-series
- **Compression**: Automatic optimization in S3/Redshift
- **Caching**: Query result caching in Streamlit

### **5. Enterprise Operations**
- **Infrastructure as Code**: 100% Terraform managed
- **Monitoring-first**: Comprehensive observability
- **Cost controls**: Budget alerts and optimization
- **Security**: IAM roles with least privilege

## 📊 Performance Characteristics

### **Processing Performance**
- **ETL Job**: 3M records in 3m 27s (14,500 records/sec)
- **Aggregation**: 5 business tables in 2m 39s
- **Query Performance**: Sub-second analytical queries
- **Storage Efficiency**: 546 optimally partitioned files

### **Scalability Metrics**
- **Data Volume**: Handles 48MB to multi-GB datasets
- **Compute**: Auto-scales from 2 to 10 Glue workers
- **Storage**: Unlimited S3 capacity with tiering
- **Analytics**: Redshift scales from 32 to 512+ RPU

### **Cost Optimization**
- **Storage**: S3 lifecycle policies (IA at 30 days, Glacier at 90)
- **Compute**: Serverless pay-per-use model
- **Monitoring**: $50 monthly budget with alerts
- **Efficiency**: Partitioned data reduces scan costs

## 🔒 Security Architecture

### **Identity & Access Management**
- **Service Roles**: Dedicated IAM roles per service
- **Least Privilege**: Minimal required permissions
- **Cross-Service**: Secure service-to-service communication
- **Encryption**: At-rest and in-transit data protection

### **Network Security**
- **VPC**: Isolated network environment
- **Security Groups**: Restrictive ingress/egress rules
- **Endpoints**: VPC endpoints for AWS services
- **Secrets**: Managed credentials in AWS Secrets Manager

### **Data Security**
- **Encryption**: S3 SSE-S3, Redshift encryption
- **Access Control**: Resource-based policies
- **Audit Trail**: CloudTrail for API logging
- **Data Masking**: PII protection in development

## 🎨 Technology Stack

### **Infrastructure**
- **IaC**: Terraform 1.5+
- **Cloud Provider**: AWS
- **Networking**: VPC, Security Groups
- **Storage**: S3, EBS

### **Data Processing**
- **ETL Engine**: AWS Glue 4.0
- **Compute**: PySpark on Glue workers
- **Orchestration**: Glue triggers and schedules
- **Catalog**: AWS Glue Data Catalog

### **Analytics & BI**
- **Data Warehouse**: Amazon Redshift Serverless
- **Query Engine**: Redshift Spectrum
- **Dashboard**: Streamlit + Plotly
- **Language**: Python 3.10, SQL

### **Monitoring & Operations**
- **Metrics**: Amazon CloudWatch
- **Alerting**: Amazon SNS
- **Cost Management**: AWS Budgets
- **Logging**: CloudWatch Logs

## 🔄 DevOps & Operations

### **Deployment Strategy**
- **Infrastructure**: Terraform state management
- **Application**: Git-based version control
- **CI/CD**: Manual deployment with automation hooks
- **Environment**: Single dev environment (extensible)

### **Monitoring Strategy**
- **Health Checks**: Automated pipeline validation
- **Performance**: Query execution monitoring
- **Cost**: Budget alerts and optimization
- **Quality**: Data validation and consistency checks

### **Disaster Recovery**
- **Backup**: S3 cross-region replication (configurable)
- **Recovery**: Terraform-based infrastructure recreation
- **Data**: Immutable data lake with versioning
- **RTO/RPO**: 4-hour recovery, 1-hour data loss maximum

---

This architecture demonstrates **enterprise-grade data engineering capabilities** suitable for production workloads, with modern cloud-native patterns and comprehensive operational excellence. 