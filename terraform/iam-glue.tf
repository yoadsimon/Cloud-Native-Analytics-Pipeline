# IAM Roles and Policies for AWS Glue
# Provides least-privilege access for Glue ETL jobs

# Trust policy for Glue service
data "aws_iam_policy_document" "glue_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM role for Glue ETL jobs
resource "aws_iam_role" "glue_etl_role" {
  name               = "${local.project_name}-glue-etl-role"
  assume_role_policy = data.aws_iam_policy_document.glue_trust_policy.json

  tags = merge(local.common_tags, {
    Name    = "${local.project_name}-glue-etl-role"
    Purpose = "Glue ETL job execution"
  })
}

# Custom S3 policy for Glue to access our specific bucket
data "aws_iam_policy_document" "glue_s3_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.data_pipeline.arn,
      "${aws_s3_bucket.data_pipeline.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets"
    ]
    resources = ["*"]
  }
}

# Custom CloudWatch Logs policy for Glue
data "aws_iam_policy_document" "glue_logs_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*"
    ]
  }
}

# Custom Glue Data Catalog policy
data "aws_iam_policy_document" "glue_catalog_policy" {
  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateDatabase",
      "glue:UpdateDatabase",
      "glue:DeleteDatabase",
      "glue:GetTable",
      "glue:GetTables",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:CreatePartition",
      "glue:UpdatePartition",
      "glue:DeletePartition",
      "glue:BatchCreatePartition",
      "glue:BatchDeletePartition",
      "glue:BatchUpdatePartition"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${local.project_name}*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.project_name}*/*"
    ]
  }
}

# Create IAM policies from the policy documents
resource "aws_iam_policy" "glue_s3_policy" {
  name        = "${local.project_name}-glue-s3-policy"
  description = "S3 access policy for Glue ETL jobs"
  policy      = data.aws_iam_policy_document.glue_s3_policy.json

  tags = merge(local.common_tags, {
    Name    = "${local.project_name}-glue-s3-policy"
    Purpose = "S3 access for Glue"
  })
}

resource "aws_iam_policy" "glue_logs_policy" {
  name        = "${local.project_name}-glue-logs-policy"
  description = "CloudWatch Logs access policy for Glue ETL jobs"
  policy      = data.aws_iam_policy_document.glue_logs_policy.json

  tags = merge(local.common_tags, {
    Name    = "${local.project_name}-glue-logs-policy"
    Purpose = "CloudWatch Logs access for Glue"
  })
}

resource "aws_iam_policy" "glue_catalog_policy" {
  name        = "${local.project_name}-glue-catalog-policy"
  description = "Glue Data Catalog access policy"
  policy      = data.aws_iam_policy_document.glue_catalog_policy.json

  tags = merge(local.common_tags, {
    Name    = "${local.project_name}-glue-catalog-policy"
    Purpose = "Data Catalog access for Glue"
  })
}

# Attach AWS managed policy for Glue service
resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_etl_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Attach our custom policies to the Glue role
resource "aws_iam_role_policy_attachment" "glue_s3_attachment" {
  role       = aws_iam_role.glue_etl_role.name
  policy_arn = aws_iam_policy.glue_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "glue_logs_attachment" {
  role       = aws_iam_role.glue_etl_role.name
  policy_arn = aws_iam_policy.glue_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "glue_catalog_attachment" {
  role       = aws_iam_role.glue_etl_role.name
  policy_arn = aws_iam_policy.glue_catalog_policy.arn
} 