# SNS Topic for DSpace alerts
resource "aws_sns_topic" "dspace_alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.dspace_alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_notification_email
}

# Extract target group ARN suffix for CloudWatch dimensions
locals {
  ui_target_group_arn_suffix  = split("/", var.ui_target_group_arn)[2]
  api_target_group_arn_suffix = var.public_api_target_group_arn != null && var.public_api_target_group_arn != "" ? split("/", var.public_api_target_group_arn)[2] : ""
}

# CloudWatch Alarm for DSpace UI availability
resource "aws_cloudwatch_metric_alarm" "dspace_ui_unavailable" {
  alarm_name          = "DSpace-${title(var.environment)}-Unavailable"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert when DSpace ${var.environment} frontend becomes unavailable"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup = local.ui_target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.dspace_alerts.arn]
  ok_actions    = [aws_sns_topic.dspace_alerts.arn]

  depends_on = [
    aws_ecs_service.dspace_angular_service
  ]
}

# CloudWatch Alarm for DSpace API availability
resource "aws_cloudwatch_metric_alarm" "dspace_api_unavailable" {
  count = var.public_api_target_group_arn != "" && var.public_api_target_group_arn != null ? 1 : 0

  alarm_name          = "DSpace-${title(var.environment)}-API-Unavailable"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert when DSpace ${var.environment} API becomes unavailable"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup = local.api_target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.dspace_alerts.arn]
  ok_actions    = [aws_sns_topic.dspace_alerts.arn]

  depends_on = [
    aws_ecs_service.dspace_api_service
  ]
}
