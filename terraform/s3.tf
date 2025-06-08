# S3 Bucket for Data Pipeline Storage
# Stores raw, staging, and curated data with lifecycle policies

# Main S3 bucket for the data pipeline
resource "aws_s3_bucket" "data_pipeline" {
  bucket = local.bucket_name

  tags = merge(local.common_tags, {
    Name        = "${local.project_name}-data-bucket"
    Purpose     = "Data-Pipeline-Storage"
    DataLayers  = "raw-staging-curated"
  })
}

# S3 bucket versioning configuration
resource "aws_s3_bucket_versioning" "data_pipeline" {
  bucket = aws_s3_bucket.data_pipeline.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data_pipeline" {
  bucket = aws_s3_bucket.data_pipeline.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# S3 bucket public access block (security best practice)
resource "aws_s3_bucket_public_access_block" "data_pipeline" {
  bucket = aws_s3_bucket.data_pipeline.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket lifecycle configuration for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "data_pipeline" {
  count  = var.enable_lifecycle_policy ? 1 : 0
  bucket = aws_s3_bucket.data_pipeline.id

  rule {
    id     = "data_pipeline_lifecycle"
    status = "Enabled"

    # Raw data lifecycle (keep longer for compliance)
    filter {
      prefix = "raw/"
    }

    transition {
      days          = var.transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.transition_to_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "staging_data_lifecycle"
    status = "Enabled"

    # Staging data lifecycle (shorter retention)
    filter {
      prefix = "staging/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }

  rule {
    id     = "curated_data_lifecycle"
    status = "Enabled"

    # Curated data lifecycle (medium retention)
    filter {
      prefix = "curated/"
    }

    transition {
      days          = var.transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.transition_to_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = 180
    }
  }
}

# Create folder structure using S3 objects
resource "aws_s3_object" "raw_folder" {
  bucket = aws_s3_bucket.data_pipeline.id
  key    = "raw/"
  content_type = "application/x-directory"

  tags = merge(local.common_tags, {
    Purpose = "Raw data storage"
  })
}

resource "aws_s3_object" "staging_folder" {
  bucket = aws_s3_bucket.data_pipeline.id
  key    = "staging/"
  content_type = "application/x-directory"

  tags = merge(local.common_tags, {
    Purpose = "Staging data storage"
  })
}

resource "aws_s3_object" "curated_folder" {
  bucket = aws_s3_bucket.data_pipeline.id
  key    = "curated/"
  content_type = "application/x-directory"

  tags = merge(local.common_tags, {
    Purpose = "Curated data storage"
  })
}

# Additional folders for logs and scripts
resource "aws_s3_object" "logs_folder" {
  bucket = aws_s3_bucket.data_pipeline.id
  key    = "logs/"
  content_type = "application/x-directory"

  tags = merge(local.common_tags, {
    Purpose = "ETL job logs"
  })
}

resource "aws_s3_object" "scripts_folder" {
  bucket = aws_s3_bucket.data_pipeline.id
  key    = "scripts/"
  content_type = "application/x-directory"

  tags = merge(local.common_tags, {
    Purpose = "ETL scripts storage"
  })
} 