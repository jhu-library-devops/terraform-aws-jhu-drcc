locals {
  dspace_api_service_name     = length(aws_ecs_service.dspace_api_service) > 0 ? aws_ecs_service.dspace_api_service[0].name : ""
  dspace_angular_service_name = aws_ecs_service.dspace_angular_service.name
  cluster_name                = split("/", var.ecs_cluster_arn)[1]

  cpu_metrics = [
    ["AWS/ECS", "CPUUtilization", "ServiceName", local.dspace_api_service_name, "ClusterName", local.cluster_name],
    [".", ".", ".", local.dspace_angular_service_name, ".", "."]
  ]

  memory_metrics = [
    ["AWS/ECS", "MemoryUtilization", "ServiceName", local.dspace_api_service_name, "ClusterName", local.cluster_name],
    [".", ".", ".", local.dspace_angular_service_name, ".", "."]
  ]

  task_count_metrics = [
    ["AWS/ECS", "RunningTaskCount", "ServiceName", local.dspace_api_service_name, "ClusterName", local.cluster_name, { "stat" : "Average" }],
    [".", ".", ".", local.dspace_angular_service_name, ".", ".", { "stat" : "Average" }]
  ]
}

resource "aws_cloudwatch_dashboard" "dspace_application" {
  dashboard_name = "${var.project_name}-${var.environment}-application"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = local.cpu_metrics
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "DSpace Application CPU Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = local.memory_metrics
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "DSpace Application Memory Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          metrics = local.task_count_metrics
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "DSpace Application Running Task Count"
          period  = 300
          stat    = "Average"
        }
      }
    ]
  })
}
