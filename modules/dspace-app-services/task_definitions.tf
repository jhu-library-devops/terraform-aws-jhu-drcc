# Task Definition Resources for DSpace Application Services
# These resources are conditionally created based on use_external_task_definitions flag

# DSpace API Task Definition
resource "aws_ecs_task_definition" "dspace_api" {
  count = var.use_external_task_definitions ? 0 : 1

  family                   = "${var.organization}-${var.environment}-dspace-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.dspace_api_cpu
  memory                   = var.dspace_api_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "${var.organization}-${var.environment}-dspace-api"
    image     = var.dspace_api_image
    cpu       = var.dspace_api_cpu
    memory    = var.dspace_api_memory
    essential = true

    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]

    environment = [
      { name = "assetstore__P__index__P__primary", value = "0" },
      { name = "assetstore__P__s3__P__bucketName", value = var.dspace_asset_store_bucket_name },
      { name = "assetstore__P__s3__P__enabled", value = "true" },
      { name = "assetstore__P__s3__P__useRelativePath", value = "false" }
    ]

    secrets = concat(
      var.dspace_server_url_ssm_arn != null ? [
        { name = "dspace__P__server__P__url", valueFrom = var.dspace_server_url_ssm_arn }
      ] : [],
      var.dspace_server_ssr_url_ssm_arn != null ? [
        { name = "dspace__P__server__P__ssr__P__url", valueFrom = var.dspace_server_ssr_url_ssm_arn }
      ] : [],
      var.dspace_ui_url_ssm_arn != null ? [
        { name = "dspace__P__ui__P__url", valueFrom = var.dspace_ui_url_ssm_arn }
      ] : [],
      var.dspace_db_url_ssm_arn != null ? [
        { name = "db__P__url", valueFrom = var.dspace_db_url_ssm_arn }
      ] : [],
      var.dspace_db_username_ssm_arn != null ? [
        { name = "db__P__username", valueFrom = var.dspace_db_username_ssm_arn }
      ] : [],
      var.dspace_db_password_ssm_arn != null ? [
        { name = "db__P__password", valueFrom = var.dspace_db_password_ssm_arn }
      ] : [],
      var.dspace_solr_url_ssm_arn != null ? [
        { name = "solr__P__server", valueFrom = var.dspace_solr_url_ssm_arn }
      ] : [],
      var.dspace_mail_server_ssm_arn != null ? [
        { name = "mail__P__server", valueFrom = var.dspace_mail_server_ssm_arn }
      ] : [],
      var.dspace_mail_port_ssm_arn != null ? [
        { name = "mail__P__server__P__port", valueFrom = var.dspace_mail_port_ssm_arn }
      ] : [],
      var.dspace_mail_username_ssm_arn != null ? [
        { name = "mail__P__server__P__username", valueFrom = var.dspace_mail_username_ssm_arn }
      ] : [],
      var.dspace_mail_password_ssm_arn != null ? [
        { name = "mail__P__server__P__password", valueFrom = var.dspace_mail_password_ssm_arn }
      ] : [],
      var.dspace_mail_disabled_ssm_arn != null ? [
        { name = "mail__P__server__P__disabled", valueFrom = var.dspace_mail_disabled_ssm_arn }
      ] : [],
      var.dspace_api_java_opts_ssm_arn != null ? [
        { name = "JAVA_OPTS", valueFrom = var.dspace_api_java_opts_ssm_arn }
      ] : [],
      var.dspace_google_analytics_key_ssm_arn != null ? [
        { name = "google__P__analytics__P__key", valueFrom = var.dspace_google_analytics_key_ssm_arn }
      ] : [],
      var.dspace_google_analytics_cron_ssm_arn != null ? [
        { name = "google__P__analytics__P__cron", valueFrom = var.dspace_google_analytics_cron_ssm_arn }
      ] : [],
      var.dspace_google_analytics_api_secret_ssm_arn != null ? [
        { name = "google__P__analytics__P__api__D__secret", valueFrom = var.dspace_google_analytics_api_secret_ssm_arn }
      ] : []
    )

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.dspace_api_log_group_name != null ? var.dspace_api_log_group_name : "/ecs/${var.organization}-${var.environment}-dspace-api"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  lifecycle {
    ignore_changes = [container_definitions]
  }

  tags = local.tags
}


# DSpace Angular Task Definition
resource "aws_ecs_task_definition" "dspace_angular" {
  count = var.use_external_task_definitions ? 0 : 1

  family                   = "${var.organization}-${var.environment}-dspace-angular"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.dspace_angular_cpu
  memory                   = var.dspace_angular_memory
  execution_role_arn       = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "${var.organization}-${var.environment}-dspace-angular"
    image     = var.dspace_angular_image
    cpu       = var.dspace_angular_cpu
    memory    = var.dspace_angular_memory
    essential = true

    portMappings = [{
      containerPort = 4000
      protocol      = "tcp"
    }]

    environment = [
      { name = "DSPACE_MARKDOWN_ENABLED", value = "true" },
      { name = "DSPACE_HOMEPAGE_RECENTSUBMISSIONS_PAGESIZE", value = "5" },
      { name = "DSPACE_UI_HOST", value = "0.0.0.0" },
      { name = "DSPACE_UI_NAMESPACE", value = "/" },
      { name = "DSPACE_REST_NAMESPACE", value = "/server" },
      { name = "DSPACE_UI_SSL", value = "false" },
      { name = "DSPACE_UI_PORT", value = "4000" },
      { name = "DSPACE_REST_SSL", value = "true" },
      { name = "DSPACE_REST_PORT", value = "" }
    ]

    secrets = concat(
      var.dspace_rest_host_ssm_arn != null ? [
        { name = "DSPACE_REST_HOST", valueFrom = var.dspace_rest_host_ssm_arn }
      ] : [],
      var.dspace_rest_ssr_url_ssm_arn != null ? [
        { name = "DSPACE_REST_SSRBASEURL", valueFrom = var.dspace_rest_ssr_url_ssm_arn }
      ] : [],
      var.dspace_angular_node_opts_ssm_arn != null ? [
        { name = "NODE_OPTIONS", valueFrom = var.dspace_angular_node_opts_ssm_arn }
      ] : []
    )

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.dspace_angular_log_group_name != null ? var.dspace_angular_log_group_name : "/ecs/${var.organization}-${var.environment}-dspace-angular"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  lifecycle {
    ignore_changes = [container_definitions]
  }

  tags = local.tags
}

# DSpace Jobs Task Definition
resource "aws_ecs_task_definition" "dspace_jobs" {
  count = var.use_external_task_definitions ? 0 : 1

  family                   = "${var.organization}-${var.environment}-dspace-jobs"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.dspace_jobs_cpu
  memory                   = var.dspace_jobs_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "${var.organization}-${var.environment}-dspace-jobs"
    image     = var.dspace_jobs_image
    cpu       = var.dspace_jobs_cpu
    memory    = var.dspace_jobs_memory
    essential = true

    # No port mappings for background job processor

    environment = [
      { name = "assetstore__P__index__P__primary", value = "0" },
      { name = "assetstore__P__s3__P__bucketName", value = var.dspace_asset_store_bucket_name },
      { name = "assetstore__P__s3__P__enabled", value = "true" },
      { name = "assetstore__P__s3__P__useRelativePath", value = "false" }
    ]

    secrets = concat(
      var.dspace_server_url_ssm_arn != null ? [
        { name = "dspace__P__server__P__url", valueFrom = var.dspace_server_url_ssm_arn }
      ] : [],
      var.dspace_server_ssr_url_ssm_arn != null ? [
        { name = "dspace__P__server__P__ssr__P__url", valueFrom = var.dspace_server_ssr_url_ssm_arn }
      ] : [],
      var.dspace_ui_url_ssm_arn != null ? [
        { name = "dspace__P__ui__P__url", valueFrom = var.dspace_ui_url_ssm_arn }
      ] : [],
      var.dspace_db_url_ssm_arn != null ? [
        { name = "db__P__url", valueFrom = var.dspace_db_url_ssm_arn }
      ] : [],
      var.dspace_db_username_ssm_arn != null ? [
        { name = "db__P__username", valueFrom = var.dspace_db_username_ssm_arn }
      ] : [],
      var.dspace_db_password_ssm_arn != null ? [
        { name = "db__P__password", valueFrom = var.dspace_db_password_ssm_arn }
      ] : [],
      var.dspace_solr_url_ssm_arn != null ? [
        { name = "solr__P__server", valueFrom = var.dspace_solr_url_ssm_arn }
      ] : [],
      var.dspace_mail_server_ssm_arn != null ? [
        { name = "mail__P__server", valueFrom = var.dspace_mail_server_ssm_arn }
      ] : [],
      var.dspace_mail_port_ssm_arn != null ? [
        { name = "mail__P__server__P__port", valueFrom = var.dspace_mail_port_ssm_arn }
      ] : [],
      var.dspace_mail_username_ssm_arn != null ? [
        { name = "mail__P__server__P__username", valueFrom = var.dspace_mail_username_ssm_arn }
      ] : [],
      var.dspace_mail_password_ssm_arn != null ? [
        { name = "mail__P__server__P__password", valueFrom = var.dspace_mail_password_ssm_arn }
      ] : [],
      var.dspace_mail_disabled_ssm_arn != null ? [
        { name = "mail__P__server__P__disabled", valueFrom = var.dspace_mail_disabled_ssm_arn }
      ] : [],
      var.dspace_jobs_java_opts_ssm_arn != null ? [
        { name = "JAVA_OPTS", valueFrom = var.dspace_jobs_java_opts_ssm_arn }
      ] : []
    )

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.dspace_jobs_log_group_name != null ? var.dspace_jobs_log_group_name : "/ecs/${var.organization}-${var.environment}-dspace-jobs"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  lifecycle {
    ignore_changes = [container_definitions]
  }

  tags = local.tags
}
