# ECS Cluster — shared compute platform for batch/ETL workloads on JHUnet
resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name
  tags = local.tags

  setting {
    name  = "containerInsights"
    value = var.container_insights_value
  }

  dynamic "configuration" {
    for_each = var.execute_command_logging != null ? [1] : []
    content {
      execute_command_configuration {
        logging = var.execute_command_logging
      }
    }
  }

  dynamic "service_connect_defaults" {
    for_each = var.service_connect_namespace_arn != null ? [1] : []
    content {
      namespace = var.service_connect_namespace_arn
    }
  }
}
