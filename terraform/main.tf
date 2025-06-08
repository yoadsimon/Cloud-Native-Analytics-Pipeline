# Cloud Native Analytics Pipeline Infrastructure
# Terraform configuration for AWS resources

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "Cloud-Native-Analytics-Pipeline"
      Environment = "dev"
      Owner       = "yoadsimon"
      Purpose     = "Data Engineering Portfolio"
    }
  }
}

# Data source to get current AWS caller identity
data "aws_caller_identity" "current" {}

# Data source to get current AWS region
data "aws_region" "current" {}

# Local values for consistent naming
locals {
  project_name = "cloud-native-analytics"
  bucket_name  = "${local.project_name}-pipeline-${random_id.bucket_suffix.hex}"
  
  common_tags = {
    Project     = "Cloud-Native-Analytics-Pipeline"
    Environment = "dev"
    Owner       = "yoadsimon"
    Purpose     = "Data Engineering Portfolio"
  }
}

# Random ID for unique bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
} 