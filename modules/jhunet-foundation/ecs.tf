# ECS Cluster — shared compute platform for batch/ETL workloads on JHUnet
resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name
  tags = local.tags

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }
}
