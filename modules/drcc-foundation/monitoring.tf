# Monitoring and alerting resources
resource "aws_sns_topic" "alarms" {
  count = var.enable_enhanced_monitoring ? 1 : 0
  name  = "${local.name}-${var.environment}-alarms"
  tags  = local.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.enable_enhanced_monitoring && var.alarm_notification_email != null ? 1 : 0
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_notification_email
}

# CloudWatch Alarms for ALB
resource "aws_cloudwatch_metric_alarm" "alb_http_5xx_errors" {
  count               = var.enable_enhanced_monitoring ? 1 : 0
  alarm_name          = "${local.name}-alb-5xx-errors"
  alarm_description   = "ALB is returning a high number of 5xx errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
  alarm_actions = [aws_sns_topic.alarms[0].arn]
  ok_actions    = [aws_sns_topic.alarms[0].arn]

  depends_on = [aws_lb.main]
}

# Billing Anomaly Alarms
resource "aws_cloudwatch_metric_alarm" "ecs_billing_anomaly" {
  count = var.enable_enhanced_monitoring ? 1 : 0

  alarm_name          = "DSpace-ECS-Billing-Anomaly"
  alarm_description   = "Alert when ECS cluster costs show anomalous behavior"
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "ad1"
  treat_missing_data  = "breaching"

  metric_query {
    id          = "m1"
    return_data = true
    metric {
      metric_name = "EstimatedCharges"
      namespace   = "AWS/Billing"
      period      = 86400
      stat        = "Maximum"
      dimensions = {
        Currency    = "USD"
        ServiceName = "AmazonECS"
      }
    }
  }

  metric_query {
    id          = "ad1"
    return_data = true
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
  }

  alarm_actions = [aws_sns_topic.alarms[0].arn]
  ok_actions    = [aws_sns_topic.alarms[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "total_billing_anomaly" {
  count = var.enable_enhanced_monitoring ? 1 : 0

  alarm_name          = "DSpace-Total-AWS-Billing-Anomaly"
  alarm_description   = "Alert when total AWS costs show anomalous behavior"
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "ad1"
  treat_missing_data  = "breaching"

  metric_query {
    id          = "m1"
    return_data = true
    metric {
      metric_name = "EstimatedCharges"
      namespace   = "AWS/Billing"
      period      = 86400
      stat        = "Maximum"
      dimensions = {
        Currency = "USD"
      }
    }
  }

  metric_query {
    id          = "ad1"
    return_data = true
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
  }

  alarm_actions = [aws_sns_topic.alarms[0].arn]
  ok_actions    = [aws_sns_topic.alarms[0].arn]
}

# CloudWatch Dashboard for DRCC foundation infrastructure
resource "aws_cloudwatch_dashboard" "main" {
  count = var.enable_enhanced_monitoring ? 1 : 0

  dashboard_name = "${local.name}-${var.environment}-infrastructure-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ALB widgets
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix, { "label" : "ALB Request Count" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.main.arn_suffix, { "label" : "ALB 5xx Errors" }],
            ["AWS/ApplicationELB", "TargetConnectionErrorCount", "LoadBalancer", aws_lb.main.arn_suffix, { "label" : "ALB Target Connection Errors" }],
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
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
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix, { "label" : "ALB Target Response Time (P90)", "stat" : "p90" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix, { "label" : "ALB Target Response Time (P99)", "stat" : "p99" }],
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "ALB Target Response Time"
          period  = 60
          stat    = "Average"
        }
      }
    ]
  })
}
