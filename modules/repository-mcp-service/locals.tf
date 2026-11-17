locals {
  name_prefix             = coalesce(var.resource_name_prefix, "${var.organization}-${var.environment}-${var.project_name}")
  application_environment = var.environment == "prod" ? "production" : var.environment
  container_name          = var.container_name
  log_group_name          = coalesce(var.log_group_name, "/ecs/${local.name_prefix}")

  tags = merge(var.tags, {
    Name        = local.name_prefix
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "OpenTofu"
  })

  container_environment = [
    { name = "NODE_ENV", value = "production" },
    { name = "PORT", value = tostring(var.container_port) },
    { name = "ENVIRONMENT", value = local.application_environment },
    { name = "JSCHOLARSHIP_SOLR_URL", value = var.jscholarship_solr_url },
    { name = "JSCHOLARSHIP_API_URL", value = var.jscholarship_api_url },
    { name = "JSCHOLARSHIP_PUBLIC_URL", value = var.jscholarship_public_url },
    { name = "JHRDR_SOLR_URL", value = var.jhrdr_solr_url },
    { name = "JHRDR_API_URL", value = var.jhrdr_api_url },
    { name = "JHRDR_PUBLIC_URL", value = var.jhrdr_public_url },
    { name = "LOG_LEVEL", value = coalesce(var.log_level, var.environment == "prod" ? "info" : "debug") },
    { name = "ALLOWED_HOSTS", value = var.public_hostname },
  ]

  mcp_task_definition_arn = var.use_external_task_definitions ? var.mcp_task_def_arn : aws_ecs_task_definition.mcp[0].arn

  valid_fargate_task_sizes = {
    256   = [512, 1024, 2048]
    512   = [1024, 2048, 3072, 4096]
    1024  = [2048, 3072, 4096, 5120, 6144, 7168, 8192]
    2048  = range(4096, 17408, 1024)
    4096  = range(8192, 31744, 1024)
    8192  = range(16384, 65536, 4096)
    16384 = range(32768, 131072, 8192)
  }
}
