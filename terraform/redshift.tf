# Amazon Redshift Configuration
# Serverless endpoint for cost-effective analytics workloads

# Get default VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group for Redshift
resource "aws_security_group" "redshift_sg" {
  name_prefix = "${local.project_name}-redshift-"
  vpc_id      = data.aws_vpc.default.id
  description = "Security group for Redshift cluster"

  # Allow inbound connections from your IP (for development)
  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this to your IP in production
    description = "Redshift port access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-redshift-sg"
  })
}

# Redshift subnet group
resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name       = "${local.project_name}-redshift-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-redshift-subnet-group"
  })
}

# Redshift Serverless namespace
resource "aws_redshiftserverless_namespace" "analytics_namespace" {
  namespace_name      = "${local.project_name}-namespace"
  admin_username      = var.redshift_admin_username
  admin_user_password = var.redshift_admin_password
  db_name            = "analytics_db"
  
  # IAM roles that can be assumed by Redshift
  iam_roles = [aws_iam_role.redshift_role.arn]

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-namespace"
  })
}

# Redshift Serverless workgroup
resource "aws_redshiftserverless_workgroup" "analytics_workgroup" {
  namespace_name = aws_redshiftserverless_namespace.analytics_namespace.namespace_name
  workgroup_name = "${local.project_name}-workgroup"
  
  # Base capacity in RPUs (Redshift Processing Units)
  base_capacity = 32 # Minimum for serverless, adjust based on workload
  
  # Network configuration
  subnet_ids         = data.aws_subnets.default.ids
  security_group_ids = [aws_security_group.redshift_sg.id]
  
  # Make it publicly accessible for development
  publicly_accessible = true
  
  # Enhanced VPC routing for better security (optional)
  enhanced_vpc_routing = false

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-workgroup"
  })
}

# Alternative: Traditional Redshift Cluster (commented out - use for persistent workloads)
# resource "aws_redshift_cluster" "analytics_cluster" {
#   cluster_identifier  = "${local.project_name}-cluster"
#   database_name      = "analytics_db"
#   master_username    = var.redshift_admin_username
#   master_password    = var.redshift_admin_password
#   node_type          = "dc2.large"  # Smallest available node type
#   cluster_type       = "single-node"
#   
#   # Network configuration
#   db_subnet_group_name   = aws_redshift_subnet_group.redshift_subnet_group.name
#   vpc_security_group_ids = [aws_security_group.redshift_sg.id]
#   publicly_accessible    = true
#   
#   # IAM role for S3 access
#   iam_roles = [aws_iam_role.redshift_role.arn]
#   
#   # Backup and maintenance
#   skip_final_snapshot       = true
#   automated_snapshot_retention_period = 1
#   
#   tags = merge(local.common_tags, {
#     Name = "${local.project_name}-cluster"
#   })
# } 