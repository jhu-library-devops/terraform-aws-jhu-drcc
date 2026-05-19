locals {
  name = "${var.project_name}-${var.environment}"

  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "OpenTofu"
      Network     = "jhunet"
    },
    var.tags
  )

  ecs_sg_name        = coalesce(var.ecs_security_group_name, "${local.name}-ecs-tasks-sg")
  ecs_sg_description = coalesce(var.ecs_security_group_description, "Security group for ECS batch/ETL tasks on JHUnet. Egress only.")

  ecs_role_name = coalesce(var.ecs_role_name, "${local.name}-ecsRole")

  log_group_name = coalesce(var.cloudwatch_log_group_name, "/ecs/${local.name}")
}
