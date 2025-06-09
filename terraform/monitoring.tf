# CloudWatch Monitoring and Alerting Infrastructure
# Monitors Glue jobs, Redshift performance, and costs

# SNS Topic for alerts
resource "aws_sns_topic" "pipeline_alerts" {
  name = "${local.project_name}-pipeline-alerts"
  
  tags = merge(local.common_tags, {
    Name = "${local.project_name}-pipeline-alerts"
    Purpose = "Pipeline monitoring and alerting"
  })
}

# SNS Topic subscription (email)
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.pipeline_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email # Add this variable
}

# CloudWatch Log Group for custom metrics
resource "aws_cloudwatch_log_group" "pipeline_logs" {
  name              = "/aws/analytics-pipeline/${local.project_name}"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-pipeline-logs"
  })
}

# ==============================================
# GLUE JOB MONITORING
# ==============================================

# CloudWatch Alarm: Glue ETL Job Failures
resource "aws_cloudwatch_metric_alarm" "glue_etl_failures" {
  alarm_name          = "${local.project_name}-glue-etl-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "glue.driver.aggregate.numFailedTasks"
  namespace           = "Glue"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors glue etl job failures"
  alarm_actions       = [aws_sns_topic.pipeline_alerts.arn]

  dimensions = {
    JobName = aws_glue_job.nyc_taxi_etl.name
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-glue-etl-failures"
  })
}

# CloudWatch Alarm: Glue Job Duration (Long Running)
resource "aws_cloudwatch_metric_alarm" "glue_etl_duration" {
  alarm_name          = "${local.project_name}-glue-etl-long-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "glue.driver.ExecutorRunTime"
  namespace           = "Glue"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "600000" # 10 minutes in milliseconds
  alarm_description   = "This metric monitors glue etl job duration"
  alarm_actions       = [aws_sns_topic.pipeline_alerts.arn]

  dimensions = {
    JobName = aws_glue_job.nyc_taxi_etl.name
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-glue-etl-duration"
  })
}

# CloudWatch Alarm: Curated Aggregations Job Failures
resource "aws_cloudwatch_metric_alarm" "glue_curated_failures" {
  alarm_name          = "${local.project_name}-glue-curated-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "glue.driver.aggregate.numFailedTasks"
  namespace           = "Glue"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors curated aggregations job failures"
  alarm_actions       = [aws_sns_topic.pipeline_alerts.arn]

  dimensions = {
    JobName = aws_glue_job.curated_aggregations.name
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-glue-curated-failures"
  })
}

# ==============================================
# REDSHIFT MONITORING
# ==============================================

# CloudWatch Alarm: Redshift CPU Utilization
resource "aws_cloudwatch_metric_alarm" "redshift_cpu" {
  alarm_name          = "${local.project_name}-redshift-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/Redshift-Serverless"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors redshift CPU utilization"
  alarm_actions       = [aws_sns_topic.pipeline_alerts.arn]

  dimensions = {
    WorkgroupName = aws_redshiftserverless_workgroup.analytics_workgroup.workgroup_name
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-redshift-cpu"
  })
}

# ==============================================
# COST MONITORING
# ==============================================

# CloudWatch Alarm: Daily Spend
resource "aws_cloudwatch_metric_alarm" "daily_spend" {
  alarm_name          = "${local.project_name}-daily-spend-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400" # 24 hours
  statistic           = "Maximum"
  threshold           = "10" # $10 daily limit
  alarm_description   = "Alert when daily spend exceeds $10"
  alarm_actions       = [aws_sns_topic.pipeline_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-daily-spend"
  })
}

# ==============================================
# CUSTOM DASHBOARD
# ==============================================

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "pipeline_dashboard" {
  dashboard_name = "${local.project_name}-pipeline-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["Glue", "glue.driver.aggregate.numCompletedTasks", "JobName", aws_glue_job.nyc_taxi_etl.name],
            ["Glue", "glue.driver.aggregate.numFailedTasks", "JobName", aws_glue_job.nyc_taxi_etl.name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Glue ETL Job Performance"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Redshift-Serverless", "CPUUtilization", "WorkgroupName", aws_redshiftserverless_workgroup.analytics_workgroup.workgroup_name],
            ["AWS/Redshift-Serverless", "ComputeCapacity", "WorkgroupName", aws_redshiftserverless_workgroup.analytics_workgroup.workgroup_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Redshift Performance"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Estimated Daily Charges"
          period  = 86400
        }
      }
    ]
  })

  # Note: CloudWatch Dashboard resource doesn't support tags
} 