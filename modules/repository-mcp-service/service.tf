resource "aws_cloudwatch_log_group" "mcp" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

resource "aws_ecs_service" "mcp" {
  name            = "${local.name_prefix}-service"
  cluster         = var.ecs_cluster_id
  task_definition = local.mcp_task_definition_arn
  desired_count   = var.service_desired_count

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider
    weight            = 1
    base              = var.service_min_count
  }

  platform_version = "LATEST"

  enable_execute_command             = true
  health_check_grace_period_seconds  = 120
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  wait_for_steady_state              = false

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    assign_public_ip = false
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.mcp.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.mcp.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  tags = local.tags

  depends_on = [
    aws_lb_listener_rule.mcp,
    terraform_data.validate_configuration,
  ]

  lifecycle {
    ignore_changes = [desired_count]
  }
}
