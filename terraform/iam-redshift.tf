# IAM Roles and Policies for Amazon Redshift
# Provides access for Redshift to read from S3 and write logs

# Trust policy for Redshift service
data "aws_iam_policy_document" "redshift_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["redshift.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM role for Redshift cluster
resource "aws_iam_role" "redshift_role" {
  name               = "${local.project_name}-redshift-role"
  assume_role_policy = data.aws_iam_policy_document.redshift_trust_policy.json

  tags = merge(local.common_tags, {
    Name    = "${local.project_name}-redshift-role"
    Purpose = "Redshift cluster data access"
  })
}

# Custom S3 policy for Redshift to access our data bucket
data "aws_iam_policy_document" "redshift_s3_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.data_pipeline.arn,
      "${aws_s3_bucket.data_pipeline.arn}/*"
    ]
  }

  # Allow Redshift to access curated data specifically
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.data_pipeline.arn}/curated/*"
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

# CloudWatch Logs policy for Redshift
data "aws_iam_policy_document" "redshift_logs_policy" {
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
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/redshift/*"
    ]
  }
}

# Create IAM policies for Redshift
resource "aws_iam_policy" "redshift_s3_policy" {
  name        = "${local.project_name}-redshift-s3-policy"
  description = "S3 access policy for Redshift cluster"
  policy      = data.aws_iam_policy_document.redshift_s3_policy.json

  tags = merge(local.common_tags, {
    Name    = "${local.project_name}-redshift-s3-policy"
    Purpose = "S3 access for Redshift"
  })
}

resource "aws_iam_policy" "redshift_logs_policy" {
  name        = "${local.project_name}-redshift-logs-policy"
  description = "CloudWatch Logs policy for Redshift cluster"
  policy      = data.aws_iam_policy_document.redshift_logs_policy.json

  tags = merge(local.common_tags, {
    Name    = "${local.project_name}-redshift-logs-policy"
    Purpose = "CloudWatch Logs for Redshift"
  })
}

# Attach policies to the Redshift role
resource "aws_iam_role_policy_attachment" "redshift_s3_attachment" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = aws_iam_policy.redshift_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "redshift_logs_attachment" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = aws_iam_policy.redshift_logs_policy.arn
}

# Optional: Attach AWS managed policy for Redshift enhanced VPC routing
# Uncomment if you plan to use VPC endpoints
# resource "aws_iam_role_policy_attachment" "redshift_enhanced_vpc" {
#   role       = aws_iam_role.redshift_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftEnhancedVpcRoutingRole"
# } 