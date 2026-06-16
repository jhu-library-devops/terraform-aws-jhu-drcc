# =============================================================================
# MONITORING AND ALERTING
# =============================================================================
# CloudWatch alarms, dashboard, and long-running task detection Lambda.
#
# All resources are gated on var.enable_enhanced_monitoring. Alarm actions
# use null-safe SNS: when var.sns_topic_arn is provided, alarms notify that
# topic; when null, alarms still create with empty action lists (visible in
# CloudWatch but silent until a topic is wired up).
#
# The long-running task detection section deploys a Lambda on a daily schedule
# that checks for non-service ECS tasks running longer than 24 hours.
# When sns_topic_arn is null, a dedicated SNS topic is created for
# long-running task alerts.
# =============================================================================

# -----------------------------------------------------------------------------
# Locals for monitoring
# -----------------------------------------------------------------------------

locals {
  long_running_task_zip   = "${path.module}/lambda/.zip/long_running_task_check.zip"
  ecs_cluster_name_prefix = "${local.name_prefix}-ecs"

  # Resolution order: created topic → external ARN → null
  long_running_tasks_alarm_topic = try(coalesce(
    length(aws_sns_topic.long_running_tasks) > 0 ? aws_sns_topic.long_running_tasks[0].arn : null,
    var.sns_topic_arn,
  ), null)
}

# =============================================================================
# CLOUDWATCH ALARMS
# =============================================================================

# -----------------------------------------------------------------------------
# Public-facing target group health
# Fires when the proxy target group has no healthy hosts available.
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_proxy_unhealthy_hosts" {
  count               = var.enable_enhanced_monitoring ? 1 : 0
  alarm_name          = "${local.name_prefix}-alb-proxy-unhealthy-hosts"
  alarm_description   = "Vireo proxy target group has no healthy hosts available"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.proxy.arn_suffix
    LoadBalancer = aws_lb.public.arn_suffix
  }

  alarm_actions = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions    = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  tags          = local.tags

  depends_on = [aws_lb_target_group.proxy]
}

# -----------------------------------------------------------------------------
# Public ALB 5xx errors
# Fires when the public ALB returns a high number of 5xx errors.
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_public_5xx_errors" {
  count               = var.enable_enhanced_monitoring ? 1 : 0
  alarm_name          = "${local.name_prefix}-alb-public-5xx-errors"
  alarm_description   = "Vireo public ALB is returning a high number of 5xx errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.public.arn_suffix
  }

  alarm_actions = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions    = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  tags          = local.tags

  depends_on = [aws_lb.public]
}

# -----------------------------------------------------------------------------
# Internal ALB 5xx errors
#
# Vireo's topology has two ALBs (public → proxy → internal → app). The public
# ALB 5xx alarm above only captures errors that propagate through the proxy.
# An app-tier 5xx that the proxy masks (retries, cached fallback, error-page
# substitution) wouldn't be seen by the public ALB alarm. This alarm watches
# the internal ALB so app-tier 5xx failures are not silently absorbed.
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_internal_5xx_errors" {
  count               = var.enable_enhanced_monitoring ? 1 : 0
  alarm_name          = "${local.name_prefix}-alb-internal-5xx-errors"
  alarm_description   = "Vireo internal ALB (app tier) is returning a high number of 5xx errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.internal.arn_suffix
  }

  alarm_actions = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions    = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  tags          = local.tags

  depends_on = [aws_lb.internal]
}

# =============================================================================
# LONG-RUNNING ECS TASK DETECTION
# =============================================================================
# ECS does not natively publish a "task uptime" metric. This section deploys a
# Lambda function on a daily schedule that lists all running tasks in the
# cluster, excludes those started by an ECS service (startedBy = "ecs-svc/…"),
# and publishes a custom CloudWatch metric (Custom/ECS →
# LongRunningNonServiceTaskCount) with the count of non-service tasks running
# longer than 24 hours. A CloudWatch alarm fires when the count is >= 1.
# =============================================================================

# -----------------------------------------------------------------------------
# Dedicated SNS topic for long-running task alarm
#
# Created only when enable_enhanced_monitoring is true AND no shared SNS topic
# is provided. Subscriptions are managed outside Terraform.
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "long_running_tasks" {
  count = var.enable_enhanced_monitoring && var.sns_topic_arn == null ? 1 : 0
  name  = "${local.ecs_cluster_name_prefix}-long-running-tasks"
  tags  = local.tags
}

# -----------------------------------------------------------------------------
# Lambda IAM Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "long_running_task_check" {
  count = var.enable_enhanced_monitoring ? 1 : 0
  name  = "${local.ecs_cluster_name_prefix}-long-running-task-check"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "long_running_task_check" {
  count = var.enable_enhanced_monitoring ? 1 : 0
  name  = "${local.ecs_cluster_name_prefix}-long-running-task-check"
  role  = aws_iam_role.long_running_task_check[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "ecs:cluster" = var.ecs_cluster_id
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = "cloudwatch:PutMetricData"
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "Custom/ECS"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.ecs_cluster_name_prefix}-long-running-task-check:*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------

resource "aws_lambda_function" "long_running_task_check" {
  count            = var.enable_enhanced_monitoring ? 1 : 0
  function_name    = "${local.ecs_cluster_name_prefix}-long-running-task-check"
  description      = "Detects ECS tasks not started by a service running longer than 24 hours"
  role             = aws_iam_role.long_running_task_check[0].arn
  handler          = "long_running_task_check.handler"
  runtime          = "python3.12"
  timeout          = 60
  memory_size      = 128
  filename         = local.long_running_task_zip
  source_code_hash = filebase64sha256(local.long_running_task_zip)

  environment {
    variables = {
      ECS_CLUSTER_ARN  = var.ecs_cluster_id
      THRESHOLD_HOURS  = "24"
      METRIC_NAMESPACE = "Custom/ECS"
      METRIC_NAME      = "LongRunningNonServiceTaskCount"
      ENVIRONMENT      = var.environment
    }
  }

  tags = local.tags
}

# -----------------------------------------------------------------------------
# Lambda CloudWatch Log Group
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "long_running_task_check" {
  count             = var.enable_enhanced_monitoring ? 1 : 0
  name              = "/aws/lambda/${local.ecs_cluster_name_prefix}-long-running-task-check"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

# -----------------------------------------------------------------------------
# EventBridge Rule (daily schedule)
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "long_running_task_check" {
  count               = var.enable_enhanced_monitoring ? 1 : 0
  name                = "${local.ecs_cluster_name_prefix}-long-running-task-check"
  description         = "Triggers the long-running ECS task check Lambda daily"
  schedule_expression = "rate(24 hours)"
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "long_running_task_check" {
  count = var.enable_enhanced_monitoring ? 1 : 0
  rule  = aws_cloudwatch_event_rule.long_running_task_check[0].name
  arn   = aws_lambda_function.long_running_task_check[0].arn
}

resource "aws_lambda_permission" "long_running_task_check" {
  count         = var.enable_enhanced_monitoring ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.long_running_task_check[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.long_running_task_check[0].arn
}

# -----------------------------------------------------------------------------
# Long-Running Tasks CloudWatch Alarm
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "ecs_long_running_tasks" {
  count               = var.enable_enhanced_monitoring ? 1 : 0
  alarm_name          = "${local.ecs_cluster_name_prefix}-long-running-tasks"
  alarm_description   = "One or more ECS tasks not started by a service have been running longer than 24 hours"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "LongRunningNonServiceTaskCount"
  namespace           = "Custom/ECS"
  period              = 86400
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterArn  = var.ecs_cluster_id
    Environment = var.environment
  }

  # Use the dedicated topic for this alarm if available, otherwise fall back to
  # the shared SNS topic (which may be null on environments without one).
  alarm_actions = local.long_running_tasks_alarm_topic != null ? [local.long_running_tasks_alarm_topic] : []
  ok_actions    = local.long_running_tasks_alarm_topic != null ? [local.long_running_tasks_alarm_topic] : []
  tags          = local.tags
}

# =============================================================================
# CLOUDWATCH DASHBOARD
# =============================================================================
# Three widgets covering request/error counts, response time percentiles, and
# target-group health. Adapted to Vireo's public + internal ALB pair and
# proxy/app target groups.
# =============================================================================

resource "aws_cloudwatch_dashboard" "main" {
  count          = var.enable_enhanced_monitoring ? 1 : 0
  dashboard_name = "${local.name_prefix}-dashboard"

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
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.public.arn_suffix, { label = "Public ALB Request Count" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.public.arn_suffix, { label = "Public ALB 5xx Errors" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.internal.arn_suffix, { label = "Internal ALB 5xx Errors" }],
            ["AWS/ApplicationELB", "TargetConnectionErrorCount", "LoadBalancer", aws_lb.public.arn_suffix, { label = "Public ALB Target Connection Errors" }],
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ALB Request & Error Metrics"
          period  = 60
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.public.arn_suffix, { label = "P90", stat = "p90" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.public.arn_suffix, { label = "P99", stat = "p99" }],
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Public ALB Target Response Time"
          period  = 60
          stat    = "Average"
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
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.proxy.arn_suffix, "LoadBalancer", aws_lb.public.arn_suffix, { label = "Proxy Unhealthy Hosts" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.app.arn_suffix, "LoadBalancer", aws_lb.internal.arn_suffix, { label = "App Unhealthy Hosts" }],
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Target Group Unhealthy Hosts"
          period  = 60
          stat    = "Average"
        }
      }
    ]
  })
}
