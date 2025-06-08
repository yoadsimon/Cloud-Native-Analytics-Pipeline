# Outputs for Cloud Native Analytics Pipeline Infrastructure
# Displays important resource information after deployment

# S3 Bucket Information
output "s3_bucket_name" {
  description = "Name of the S3 bucket for data pipeline"
  value       = aws_s3_bucket.data_pipeline.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.data_pipeline.arn
}

output "s3_bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.data_pipeline.region
}

# IAM Role Information
output "glue_etl_role_arn" {
  description = "ARN of the Glue ETL execution role"
  value       = aws_iam_role.glue_etl_role.arn
}

output "glue_etl_role_name" {
  description = "Name of the Glue ETL execution role"
  value       = aws_iam_role.glue_etl_role.name
}

output "redshift_role_arn" {
  description = "ARN of the Redshift cluster role"
  value       = aws_iam_role.redshift_role.arn
}

output "redshift_role_name" {
  description = "Name of the Redshift cluster role"
  value       = aws_iam_role.redshift_role.name
}

# Account and Region Information
output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}

# Useful S3 paths for data pipeline
output "s3_raw_path" {
  description = "S3 path for raw data"
  value       = "s3://${aws_s3_bucket.data_pipeline.bucket}/raw/"
}

output "s3_staging_path" {
  description = "S3 path for staging data"
  value       = "s3://${aws_s3_bucket.data_pipeline.bucket}/staging/"
}

output "s3_curated_path" {
  description = "S3 path for curated data"
  value       = "s3://${aws_s3_bucket.data_pipeline.bucket}/curated/"
}

output "s3_logs_path" {
  description = "S3 path for logs"
  value       = "s3://${aws_s3_bucket.data_pipeline.bucket}/logs/"
}

output "s3_scripts_path" {
  description = "S3 path for scripts"
  value       = "s3://${aws_s3_bucket.data_pipeline.bucket}/scripts/"
}

# Glue Resources
output "glue_database_name" {
  description = "Name of the Glue catalog database"
  value       = aws_glue_catalog_database.analytics_db.name
}

output "glue_staging_crawler_name" {
  description = "Name of the Glue staging crawler"
  value       = aws_glue_crawler.staging_crawler.name
}

output "glue_raw_crawler_name" {
  description = "Name of the Glue raw crawler"
  value       = aws_glue_crawler.raw_crawler.name
}

output "glue_etl_job_name" {
  description = "Name of the Glue ETL job"
  value       = aws_glue_job.nyc_taxi_etl.name
}

# Project Information
output "project_name" {
  description = "Project name used for resource naming"
  value       = local.project_name
}

output "resource_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

# Redshift Outputs
output "redshift_namespace_name" {
  description = "Redshift Serverless namespace name"
  value       = aws_redshiftserverless_namespace.analytics_namespace.namespace_name
}

output "redshift_workgroup_name" {
  description = "Redshift Serverless workgroup name"
  value       = aws_redshiftserverless_workgroup.analytics_workgroup.workgroup_name
}

output "redshift_endpoint" {
  description = "Redshift Serverless endpoint"
  value       = aws_redshiftserverless_workgroup.analytics_workgroup.endpoint
}

output "redshift_database_name" {
  description = "Redshift database name"
  value       = aws_redshiftserverless_namespace.analytics_namespace.db_name
} 