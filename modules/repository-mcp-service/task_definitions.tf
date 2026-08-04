resource "aws_ecs_task_definition" "mcp" {
  count = var.use_external_task_definitions ? 0 : 1

  family                   = "${local.name_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = var.mcp_image
      essential = true

      portMappings = [
        {
          name          = "mcp-http"
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      environment = local.container_environment

      healthCheck = {
        command     = ["CMD-SHELL", "bun -e \"const r = await fetch('http://127.0.0.1:${var.container_port}/health/live'); if (!r.ok) process.exit(1);\""]
        interval    = 15
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }

      readonlyRootFilesystem = true

      linuxParameters = {
        initProcessEnabled = true
        tmpfs = [
          {
            containerPath = "/tmp"
            size          = 64
            mountOptions  = ["rw", "noexec", "nosuid"]
          },
          {
            containerPath = "/managed-agents"
            size          = 32
            mountOptions  = ["rw", "noexec", "nosuid"]
          },
          {
            containerPath = "/var/lib/amazon/ssm"
            size          = 16
            mountOptions  = ["rw", "noexec", "nosuid"]
          },
          {
            containerPath = "/var/log/amazon/ssm"
            size          = 16
            mountOptions  = ["rw", "noexec", "nosuid"]
          }
        ]
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.mcp.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = var.environment
        }
      }

      stopTimeout = 30
    }
  ])

  tags = local.tags

  depends_on = [terraform_data.validate_configuration]
}
