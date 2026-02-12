# Zookeeper-specific monitoring and alerting

# CloudWatch Alarms for Zookeeper
resource "aws_cloudwatch_metric_alarm" "zookeeper_cpu_high" {
  count = var.deploy_zookeeper && !var.use_external_task_definitions ? 1 : 0

  alarm_name          = "${local.name}-zookeeper-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors Zookeeper CPU utilization"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions          = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  treat_missing_data  = "missing"

  dimensions = {
    ServiceName = aws_ecs_service.zookeeper_fargate_service[0].name
    ClusterName = var.ecs_cluster_name
  }

}

resource "aws_cloudwatch_metric_alarm" "zookeeper_memory_high" {
  count = var.deploy_zookeeper && !var.use_external_task_definitions ? 1 : 0

  alarm_name          = "${local.name}-zookeeper-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors Zookeeper memory utilization"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions          = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  treat_missing_data  = "missing"

  dimensions = {
    ServiceName = aws_ecs_service.zookeeper_fargate_service[0].name
    ClusterName = var.ecs_cluster_name
  }

}

resource "aws_cloudwatch_metric_alarm" "zookeeper_task_count_low" {
  count = var.deploy_zookeeper && !var.use_external_task_definitions ? 1 : 0

  alarm_name          = "${local.name}-zookeeper-task-count-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors Zookeeper running task count"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions          = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = aws_ecs_service.zookeeper_fargate_service[0].name
    ClusterName = var.ecs_cluster_name
  }

}



resource "aws_cloudwatch_metric_alarm" "zookeeper_health_check_failures" {
  count = var.deploy_zookeeper ? 1 : 0

  alarm_name          = "${local.name}-zookeeper-health-failures"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  threshold           = "3"
  alarm_description   = "Zookeeper ensemble has insufficient running tasks (should be 3)"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions          = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "m1"
    return_data = false
    metric {
      metric_name = "RunningTaskCount"
      namespace   = "AWS/ECS"
      period      = 300
      stat        = "Average"
      dimensions = {
        ServiceName = "${local.name}-zookeeper-1-service"
        ClusterName = var.ecs_cluster_name
      }
    }
  }

  metric_query {
    id          = "m2"
    return_data = false
    metric {
      metric_name = "RunningTaskCount"
      namespace   = "AWS/ECS"
      period      = 300
      stat        = "Average"
      dimensions = {
        ServiceName = "${local.name}-zookeeper-2-service"
        ClusterName = var.ecs_cluster_name
      }
    }
  }

  metric_query {
    id          = "m3"
    return_data = false
    metric {
      metric_name = "RunningTaskCount"
      namespace   = "AWS/ECS"
      period      = 300
      stat        = "Average"
      dimensions = {
        ServiceName = "${local.name}-zookeeper-3-service"
        ClusterName = var.ecs_cluster_name
      }
    }
  }

  metric_query {
    id          = "e1"
    return_data = true
    expression  = "m1+m2+m3"
  }
}

# EFS monitoring
resource "aws_cloudwatch_metric_alarm" "zookeeper_efs_connections" {
  count = var.deploy_zookeeper ? 1 : 0

  alarm_name          = "${local.name}-zookeeper-efs-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ClientConnections"
  namespace           = "AWS/EFS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This metric monitors EFS client connections for Zookeeper"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions          = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  treat_missing_data  = "missing"

  dimensions = {
    FileSystemId = aws_efs_file_system.zookeeper_data[0].id
  }

}
