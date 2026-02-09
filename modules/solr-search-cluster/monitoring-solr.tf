# Monitoring and alerting resources for Solr services
# CloudWatch Alarms for Solr
resource "aws_cloudwatch_metric_alarm" "solr_cpu_high" {
  count               = var.enable_enhanced_monitoring ? 1 : 0
  alarm_name          = "${local.name}-solr-cpu-utilization-high"
  alarm_description   = "Solr service CPU utilization is high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = length(aws_ecs_service.solr_fargate_service) > 0 ? aws_ecs_service.solr_fargate_service[0].name : ""
  }
  alarm_actions = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions    = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  depends_on = [aws_ecs_service.solr_fargate_service]
}

resource "aws_cloudwatch_metric_alarm" "solr_memory_high" {
  count               = var.enable_enhanced_monitoring ? 1 : 0
  alarm_name          = "${local.name}-solr-memory-utilization-high"
  alarm_description   = "Solr service memory utilization is high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = length(aws_ecs_service.solr_fargate_service) > 0 ? aws_ecs_service.solr_fargate_service[0].name : ""
  }
  alarm_actions = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions    = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  depends_on = [aws_ecs_service.solr_fargate_service]
}

# CloudWatch Log Metric Filters for Solr Error Monitoring
resource "aws_cloudwatch_log_metric_filter" "solr_connection_errors" {
  name           = "SolrConnectionErrors"
  log_group_name = aws_cloudwatch_log_group.solr_fargate.name
  pattern        = "[timestamp, level=\"ERROR\", thread, core, class, message=\"*connection*\" || message=\"*timeout*\" || message=\"*refused*\"]"

  metric_transformation {
    name          = "SolrConnectionErrors"
    namespace     = "DSpace/Solr"
    value         = "1"
    default_value = 0
  }

}

resource "aws_cloudwatch_log_metric_filter" "zookeeper_session_errors" {
  name           = "ZookeeperSessionErrors"
  log_group_name = aws_cloudwatch_log_group.solr_fargate.name
  pattern        = "[timestamp, level=\"WARN\" || level=\"ERROR\", thread, core, class, message=\"*SessionExpired*\" || message=\"*EndOfStream*\" || message=\"*Disconnected*\"]"

  metric_transformation {
    name          = "ZookeeperSessionErrors"
    namespace     = "DSpace/Solr"
    value         = "1"
    default_value = 0
  }

}

resource "aws_cloudwatch_log_metric_filter" "solr_cluster_health_errors" {
  name           = "SolrClusterHealthErrors"
  log_group_name = aws_cloudwatch_log_group.solr_fargate.name
  pattern        = "[timestamp, level=\"ERROR\" || level=\"WARN\", thread, core, class, message=\"*cluster*\" && (message=\"*down*\" || message=\"*unhealthy*\" || message=\"*failed*\")]"

  metric_transformation {
    name          = "SolrClusterHealthErrors"
    namespace     = "DSpace/Solr"
    value         = "1"
    default_value = 0
  }

}

# CloudWatch Alarms for Solr Error States
resource "aws_cloudwatch_metric_alarm" "solr_connection_errors" {
  alarm_name          = "DSpace-Solr-ConnectionErrors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SolrConnectionErrors"
  namespace           = "DSpace/Solr"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when Solr experiences connection errors"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions    = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

}

resource "aws_cloudwatch_metric_alarm" "zookeeper_session_errors" {
  alarm_name          = "DSpace-Solr-ZookeeperSessionErrors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ZookeeperSessionErrors"
  namespace           = "DSpace/Solr"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "Alert when Zookeeper session errors occur affecting Solr"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions    = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

}

resource "aws_cloudwatch_metric_alarm" "solr_cluster_health_errors" {
  alarm_name          = "DSpace-Solr-ClusterHealthErrors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SolrClusterHealthErrors"
  namespace           = "DSpace/Solr"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alert when Solr cluster health issues are detected"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions    = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

}

# CloudWatch Dashboard for Solr services
resource "aws_cloudwatch_dashboard" "solr" {
  count = var.enable_enhanced_monitoring ? 1 : 0

  dashboard_name = "${local.name}-${var.environment}-solr-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Base Solr widgets
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["ECS/ContainerInsights", "CpuUtilized", "ClusterName", var.ecs_cluster_name, "ServiceName", length(aws_ecs_service.solr_fargate_service) > 0 ? aws_ecs_service.solr_fargate_service[0].name : "", { "label" : "Solr CPU Utilization" }],
            ["ECS/ContainerInsights", "MemoryUtilized", "ClusterName", var.ecs_cluster_name, "ServiceName", length(aws_ecs_service.solr_fargate_service) > 0 ? aws_ecs_service.solr_fargate_service[0].name : "", { "label" : "Solr Memory Utilization", "yAxis" : "right" }],
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Solr Service CPU/Memory Utilization"
          period  = 300
          stat    = "Average"
          yAxis = {
            left  = { min = 0, max = 100 }
            right = { min = 0, max = 100 }
          }
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
            ["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", var.ecs_cluster_name, "ServiceName", length(aws_ecs_service.solr_fargate_service) > 0 ? aws_ecs_service.solr_fargate_service[0].name : "", { "label" : "Solr Running Tasks" }],
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Solr Service Running Tasks"
          period  = 300
          stat    = "Average"
        }
      }
    ]
  })
}

# CloudWatch Synthetics Canary for Solr Health Monitoring
resource "aws_s3_bucket" "synthetics_artifacts" {
  bucket        = lower("${var.organization}-dspace-synthetics-artifacts-${random_id.bucket_suffix.hex}")
  force_destroy = true

  lifecycle {
    ignore_changes = [bucket]
  }
}

resource "aws_s3_bucket_versioning" "synthetics_artifacts" {
  bucket = aws_s3_bucket.synthetics_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 7

  lifecycle {
    ignore_changes = [byte_length]
  }
}

resource "aws_iam_role" "synthetics_canary_role" {
  name = "${var.organization}-dspace-solr-canary-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_iam_policy" "synthetics_canary_policy" {
  name = "${var.organization}-dspace-solr-canary-policy"

  lifecycle {
    ignore_changes = [name]
  }

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.synthetics_artifacts.arn,
          "${aws_s3_bucket.synthetics_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "synthetics_canary_policy" {
  role       = aws_iam_role.synthetics_canary_role.name
  policy_arn = aws_iam_policy.synthetics_canary_policy.arn
}

data "archive_file" "canary_zip" {
  type        = "zip"
  source_file = "${path.module}/solr-health-canary.js"
  output_path = "${path.module}/solr-health-canary.zip"
}

resource "aws_security_group" "canary" {
  name        = "${local.name}-canary-sg"
  description = "Security group for Synthetics canary"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-canary-sg"
  }
}

resource "aws_synthetics_canary" "solr_health" {
  name                 = "${var.organization}-dspace-solr-health-canary"
  artifact_s3_location = "s3://${aws_s3_bucket.synthetics_artifacts.bucket}/"
  execution_role_arn   = aws_iam_role.synthetics_canary_role.arn
  handler              = "solr-health-canary.handler"
  zip_file             = "${path.module}/solr-health-canary.zip"
  runtime_version      = "syn-nodejs-puppeteer-6.2"

  schedule {
    expression = "rate(5 minutes)"
  }

  run_config {
    timeout_in_seconds = 60
    environment_variables = {
      solrUrl = "http://${length(aws_service_discovery_service.solr_individual) > 0 ? aws_service_discovery_service.solr_individual[0].name : "solr-1"}.${var.service_discovery_namespace_name}:8983/solr"
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.canary.id]
  }

  artifact_config {
    s3_encryption {
      encryption_mode = "SSE_S3"
    }
  }

  lifecycle {
    ignore_changes = [name, zip_file]
  }

  depends_on = [
    aws_iam_role_policy_attachment.synthetics_canary_policy
  ]
}

# Enhanced CloudWatch Dashboard for Solr Error Monitoring
resource "aws_cloudwatch_dashboard" "solr_monitoring" {
  dashboard_name = "DSpace-Solr-Monitoring"

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
            ["DSpace/Solr", "SolrConnectionErrors"],
            [".", "ZookeeperSessionErrors"],
            [".", "SolrClusterHealthErrors"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Solr Error Metrics"
          period  = 300
          stat    = "Sum"
          yAxis = {
            left = {
              min = 0
            }
          }
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
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${local.name}-solr-service", "ClusterName", "${local.name}-cluster"],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Solr Service Resource Usage"
          period  = 300
          stat    = "Average"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "RunningTaskCount", "ServiceName", "${local.name}-solr-service", "ClusterName", "${local.name}-cluster"],
            [".", "DesiredCount", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Solr Service Task Count"
          period  = 300
          stat    = "Average"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "RunningTaskCount", "ServiceName", "${local.name}-zookeeper-1-service", "ClusterName", "${local.name}-cluster"],
            [".", ".", "ServiceName", "${local.name}-zookeeper-2-service", ".", "."],
            [".", ".", "ServiceName", "${local.name}-zookeeper-3-service", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Zookeeper Ensemble Status"
          period  = 300
          stat    = "Average"
          yAxis = {
            left = {
              min = 0
              max = 2
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${local.name}-zookeeper-1-service", "ClusterName", "${local.name}-cluster"],
            [".", ".", "ServiceName", "${local.name}-zookeeper-2-service", ".", "."],
            [".", ".", "ServiceName", "${local.name}-zookeeper-3-service", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Zookeeper CPU Usage"
          period  = 300
          stat    = "Average"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          query  = "SOURCE '${aws_cloudwatch_log_group.solr_fargate.name}' | fields @timestamp, @message\n| filter @message like /ERROR/\n| sort @timestamp desc\n| limit 20"
          region = var.aws_region
          title  = "Recent Solr Errors"
          view   = "table"
        }
      }
    ]
  })

}
