# AWS Glue Database
resource "aws_glue_catalog_database" "analytics_db" {
  name         = "${local.project_name}-analytics-db"
  description  = "Database for NYC taxi analytics pipeline"
  
  tags = local.common_tags
}

# AWS Glue Crawler for Staging Data
resource "aws_glue_crawler" "staging_crawler" {
  name          = "${local.project_name}-staging-crawler"
  role          = aws_iam_role.glue_etl_role.arn
  database_name = aws_glue_catalog_database.analytics_db.name
  description   = "Crawler for staging layer Parquet data"

  s3_target {
    path = "s3://${aws_s3_bucket.data_pipeline.bucket}/staging/"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
      Tables = {
        AddOrUpdateBehavior = "MergeNewColumns"
      }
    }
  })

  tags = local.common_tags
}

# AWS Glue Crawler for Raw Data
resource "aws_glue_crawler" "raw_crawler" {
  name          = "${local.project_name}-raw-crawler"
  role          = aws_iam_role.glue_etl_role.arn
  database_name = aws_glue_catalog_database.analytics_db.name
  description   = "Crawler for raw NYC taxi data"

  s3_target {
    path = "s3://${aws_s3_bucket.data_pipeline.bucket}/raw/"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
      Tables = {
        AddOrUpdateBehavior = "MergeNewColumns"
      }
    }
  })

  tags = local.common_tags
}

# Glue Job for PySpark ETL Pipeline
resource "aws_glue_job" "nyc_taxi_etl" {
  name              = "${local.project_name}-nyc-taxi-etl"
  role_arn          = aws_iam_role.glue_etl_role.arn
  description       = "PySpark ETL job for NYC taxi data transformation"
  glue_version      = "4.0"
  max_retries       = 1
  timeout           = 60
  worker_type       = "G.1X"
  number_of_workers = 2

  command {
    script_location = "s3://${aws_s3_bucket.data_pipeline.bucket}/scripts/transform_nyc_taxi_glue.py"
    python_version  = "3"
  }

  default_arguments = {
    "--TempDir"                          = "s3://${aws_s3_bucket.data_pipeline.bucket}/temp/"
    "--enable-metrics"                   = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"           = "s3://${aws_s3_bucket.data_pipeline.bucket}/logs/spark-logs/"
    "--enable-job-insights"             = "true"
    "--enable-glue-datacatalog"         = "true"
    "--job-language"                    = "python"
    "--class"                           = "GlueApp"
    "--enable-continuous-cloudwatch-log" = "true"
    "--INPUT_S3_PATH"                   = "s3://${aws_s3_bucket.data_pipeline.bucket}/raw/"
    "--OUTPUT_S3_PATH"                  = "s3://${aws_s3_bucket.data_pipeline.bucket}/staging/"
    "--DATABASE_NAME"                   = aws_glue_catalog_database.analytics_db.name
  }

  execution_property {
    max_concurrent_runs = 1
  }

  tags = local.common_tags
}

# Glue Trigger for Daily ETL Job
resource "aws_glue_trigger" "daily_etl_trigger" {
  name         = "${local.project_name}-daily-etl-trigger"
  description  = "Daily trigger for NYC taxi ETL pipeline"
  type         = "SCHEDULED"
  schedule     = "cron(0 6 * * ? *)"  # Run daily at 6 AM UTC
  enabled      = false  # Start disabled for manual testing

  actions {
    job_name = aws_glue_job.nyc_taxi_etl.name
  }

  tags = local.common_tags
}

# Glue Trigger to run crawler after ETL job completes
resource "aws_glue_trigger" "post_etl_crawler_trigger" {
  name        = "${local.project_name}-post-etl-crawler"
  description = "Run staging crawler after ETL job completes"
  type        = "CONDITIONAL"
  enabled     = true

  actions {
    crawler_name = aws_glue_crawler.staging_crawler.name
  }

  predicate {
    conditions {
      job_name = aws_glue_job.nyc_taxi_etl.name
      state    = "SUCCEEDED"
    }
  }

  tags = local.common_tags
}

# Glue Job for Curated Layer Aggregations
resource "aws_glue_job" "curated_aggregations" {
  name              = "${local.project_name}-curated-aggregations"
  role_arn          = aws_iam_role.glue_etl_role.arn
  description       = "PySpark job for creating curated business aggregations"
  glue_version      = "4.0"
  max_retries       = 1
  timeout           = 30
  worker_type       = "G.1X"
  number_of_workers = 2

  command {
    script_location = "s3://${aws_s3_bucket.data_pipeline.bucket}/scripts/create_curated_aggregations.py"
    python_version  = "3"
  }

  default_arguments = {
    "--TempDir"                          = "s3://${aws_s3_bucket.data_pipeline.bucket}/temp/"
    "--enable-metrics"                   = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"           = "s3://${aws_s3_bucket.data_pipeline.bucket}/logs/spark-logs/"
    "--enable-job-insights"             = "true"
    "--enable-glue-datacatalog"         = "true"
    "--job-language"                    = "python"
    "--class"                           = "GlueApp"
    "--enable-continuous-cloudwatch-log" = "true"
    "--INPUT_S3_PATH"                   = "s3://${aws_s3_bucket.data_pipeline.bucket}/staging/"
    "--OUTPUT_S3_PATH"                  = "s3://${aws_s3_bucket.data_pipeline.bucket}/curated/"
    "--DATABASE_NAME"                   = aws_glue_catalog_database.analytics_db.name
  }

  execution_property {
    max_concurrent_runs = 1
  }

  tags = local.common_tags
}

# AWS Glue Crawler for Curated Data
resource "aws_glue_crawler" "curated_crawler" {
  name          = "${local.project_name}-curated-crawler"
  role          = aws_iam_role.glue_etl_role.arn
  database_name = aws_glue_catalog_database.analytics_db.name
  description   = "Crawler for curated aggregated data"

  s3_target {
    path = "s3://${aws_s3_bucket.data_pipeline.bucket}/curated/"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
      Tables = {
        AddOrUpdateBehavior = "MergeNewColumns"
      }
    }
  })

  tags = local.common_tags
}

# Trigger to run curated aggregations after staging crawler completes
resource "aws_glue_trigger" "curated_aggregation_trigger" {
  name        = "${local.project_name}-curated-aggregation-trigger"
  description = "Run curated aggregations after staging crawler completes"
  type        = "CONDITIONAL"
  enabled     = true

  actions {
    job_name = aws_glue_job.curated_aggregations.name
  }

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.staging_crawler.name
      crawl_state  = "SUCCEEDED"
    }
  }

  tags = local.common_tags
}

# Trigger to run curated crawler after aggregation job completes
resource "aws_glue_trigger" "post_curated_crawler_trigger" {
  name        = "${local.project_name}-post-curated-crawler"
  description = "Run curated crawler after aggregation job completes"
  type        = "CONDITIONAL"
  enabled     = true

  actions {
    crawler_name = aws_glue_crawler.curated_crawler.name
  }

  predicate {
    conditions {
      job_name = aws_glue_job.curated_aggregations.name
      state    = "SUCCEEDED"
    }
  }

  tags = local.common_tags
} 