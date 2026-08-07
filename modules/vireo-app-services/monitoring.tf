# =============================================================================
# MONITORING AND ALERTING
# =============================================================================
# CloudWatch alarms and dashboard.
#
# All resources are gated on var.enable_enhanced_monitoring. Alarm actions
# use null-safe SNS: when var.sns_topic_arn is provided, alarms notify that
# topic; when null, alarms still create with empty action lists (visible in
# CloudWatch but silent until a topic is wired up).
# =============================================================================

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
