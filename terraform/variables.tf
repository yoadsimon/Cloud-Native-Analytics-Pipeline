# Variables for Cloud Native Analytics Pipeline Infrastructure

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "cloud-native-analytics"
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
  default     = "cloud-native-analytics-pipeline"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "enable_lifecycle_policy" {
  description = "Enable S3 lifecycle policies for cost optimization"
  type        = bool
  default     = true
}

variable "transition_to_ia_days" {
  description = "Days to transition objects to Infrequent Access"
  type        = number
  default     = 30
}

variable "transition_to_glacier_days" {
  description = "Days to transition objects to Glacier"
  type        = number
  default     = 90
}

variable "expiration_days" {
  description = "Days to expire old objects"
  type        = number
  default     = 365
}

# Redshift Configuration Variables
variable "redshift_admin_username" {
  description = "Admin username for Redshift cluster"
  type        = string
  default     = "admin"
}

variable "redshift_admin_password" {
  description = "Admin password for Redshift cluster"
  type        = string
  sensitive   = true
  default     = "TempPassword123!" # Change this to a secure password
} 