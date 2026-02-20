# DSpace App Services
# This file contains the ECS services for the complete DSpace application stack

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "dspace_angular" {
  name = "/ecs/${var.environment}-dspace-angular"
  tags = local.tags

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_cloudwatch_log_group" "dspace_api" {
  name = "/ecs/${var.environment}-dspace-api"
  tags = local.tags

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_cloudwatch_log_group" "dspace_jobs" {
  name = "/ecs/${var.environment}-dspace-jobs"
  tags = local.tags

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_cloudwatch_log_group" "admin" {
  name = "/ecs/${var.environment}-admin"
  tags = local.tags
}

# DSpace Angular UI Service
resource "aws_ecs_service" "dspace_angular_service" {
  name                               = "${var.organization}-${var.environment}-${var.project_name}-angular-service"
  cluster                            = var.ecs_cluster_id
  task_definition                    = var.use_external_task_definitions ? var.dspace_angular_task_def_arn : aws_ecs_task_definition.dspace_angular[0].arn
  desired_count                      = var.dspace_angular_task_count
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ui.arn
    container_name   = "${var.organization}-${var.environment}-${var.project_name}-angular"
    container_port   = 4000
  }

  depends_on = [var.alb_https_listener_arn]
  tags       = local.tags

  lifecycle {
    ignore_changes = [desired_count, task_definition, name]
  }
}

# DSpace API Service
resource "aws_ecs_service" "dspace_api_service" {
  name                               = "${var.organization}-${var.environment}-${var.project_name}-service"
  cluster                            = var.ecs_cluster_id
  task_definition                    = var.use_external_task_definitions ? var.dspace_api_task_def_arn : aws_ecs_task_definition.dspace_api[0].arn
  desired_count                      = var.dspace_api_task_count
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  # Load balancer configuration for public API access
  load_balancer {
    target_group_arn = aws_lb_target_group.public_api.arn
    container_name   = "${var.organization}-${var.environment}-${var.project_name}-api"
    container_port   = 8080
  }

  # Load balancer configuration for private API access
  load_balancer {
    target_group_arn = aws_lb_target_group.private_api.arn
    container_name   = "${var.organization}-${var.environment}-${var.project_name}-api"
    container_port   = 8080
  }

  depends_on = [var.alb_https_listener_arn]
  tags       = local.tags

  enable_execute_command = true

  lifecycle {
    ignore_changes = [desired_count, task_definition, name]
  }
}
# Admin Service
resource "aws_ecs_service" "admin_service" {
  count           = var.deploy_admin_service ? 1 : 0
  name            = "${var.organization}-${var.environment}-admin-service"
  cluster         = var.ecs_cluster_id
  task_definition = "${var.organization}-${var.environment}-admin:1"
  desired_count   = 0
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  enable_execute_command = true
  tags                   = local.tags

  lifecycle {
    ignore_changes = [desired_count, task_definition, name]
  }
}

# DSpace Jobs Service
resource "aws_ecs_service" "dspace_jobs_service" {
  name            = "${var.organization}-${var.environment}-${var.project_name}-jobs-service"
  cluster         = var.ecs_cluster_id
  task_definition = var.use_external_task_definitions ? var.dspace_jobs_task_def_arn : aws_ecs_task_definition.dspace_jobs[0].arn
  desired_count   = 0
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  enable_execute_command = true
  tags                   = local.tags

  lifecycle {
    ignore_changes = [desired_count, task_definition, name]
  }
}
