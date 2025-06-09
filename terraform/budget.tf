# AWS Budget for Cost Control and Monitoring
# Tracks spending and provides alerts before costs exceed limits

# Budget for overall project spending
resource "aws_budgets_budget" "pipeline_budget" {
  name         = "${local.project_name}-budget"
  budget_type  = "COST"
  limit_amount = "50" # $50 monthly limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80 # Alert at 80% of budget
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100 # Alert at 100% of budget (forecast)
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 110 # Alert at 110% overspend
    threshold_type            = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-budget"
    Purpose = "Cost monitoring and control"
  })
}

# Daily budget for spending control
resource "aws_budgets_budget" "daily_pipeline_budget" {
  name         = "${local.project_name}-daily-budget"
  budget_type  = "COST"
  limit_amount = "5" # $5 daily limit
  limit_unit   = "USD"
  time_unit    = "DAILY"
  time_period_start = formatdate("YYYY-MM-DD_00:00", timestamp())

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 3 # Alert at $3 daily spend
    threshold_type            = "ABSOLUTE_VALUE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-daily-budget"
    Purpose = "Daily cost monitoring"
  })
} 