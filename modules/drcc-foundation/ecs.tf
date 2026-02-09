# ECS Cluster - Shared compute platform for all services
resource "aws_ecs_cluster" "main" {
  name = "${local.name}-cluster"
  tags = local.tags

  setting {
    name  = "containerInsights"
    value = var.enable_enhanced_monitoring ? "enabled" : "disabled"
  }
}

