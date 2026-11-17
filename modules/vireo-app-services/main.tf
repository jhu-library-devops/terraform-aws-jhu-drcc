# =============================================================================
# VIREO APPLICATION SERVICES MODULE
# =============================================================================
# Self-contained Vireo deployment with its own:
# - Public ALB (internet-facing) with WAF → proxy (port 8080)
# - Internal ALB → app (port 9000)
# - IAM roles (proxy execution, proxy task, app execution, app task)
# - Security groups (ALB, proxy, internal ALB, app)
# - ECS services for proxy and app (task definitions managed externally)
# - ECR repository (shared for proxy and app images)
# - RDS database (conditional)
# - EFS file system for asset store
# - S3 bucket for ETL
# - SSM parameters for Shibboleth SP config and app config
# - CloudWatch log groups
#
# Shared infrastructure (VPC, subnets, ECS cluster) is passed in as variables.
#
# Traffic flow:
#   Internet → Public ALB (443) → proxy ECS (8080)
#                                → Internal ALB (9000) → app ECS (9000)
# =============================================================================

data "aws_caller_identity" "current" {}

locals {
  name_prefix       = "${var.organization}-${var.environment}-${var.project_name}"
  proxy_name_prefix = "${var.organization}-${var.environment}-${var.project_name}-proxy"

  tags = merge(var.tags, {
    Name      = local.name_prefix
    ManagedBy = "OpenTofu"
  })
}

# =============================================================================
# IAM ROLES
# =============================================================================

# --- Proxy Task Execution Role ---
# Used by ECS agent to pull proxy image and fetch Shibboleth SSM parameters.
resource "aws_iam_role" "proxy_task_execution" {
  name = "${local.proxy_name_prefix}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "proxy_task_execution_base" {
  role       = aws_iam_role.proxy_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "proxy_task_execution_ssm" {
  name = "${local.proxy_name_prefix}-ssm-read"
  role = aws_iam_role.proxy_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameters", "ssm:GetParameter"]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/proxy/${var.environment}/*"
      }
    ]
  })
}

# --- App Task Execution Role ---
# Used by ECS agent to pull Vireo app image and fetch app SSM parameters.
resource "aws_iam_role" "app_task_execution" {
  name = "${local.name_prefix}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "app_task_execution_base" {
  role       = aws_iam_role.app_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "app_task_execution_ssm" {
  name = "${local.name_prefix}-ssm-read"
  role = aws_iam_role.app_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameters", "ssm:GetParameter"]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/*"
      }
    ]
  })
}

# --- Proxy Task Role ---
# Used by the running proxy container to fetch Shibboleth config from SSM
# Parameter Store via the AWS CLI in docker-entrypoint.sh.
# Also grants ECS Exec (ssmmessages) for operational debugging.
resource "aws_iam_role" "proxy_task" {
  name = "${local.proxy_name_prefix}-ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "proxy_task_ssm" {
  name = "${local.proxy_name_prefix}-ssm-read"
  role = aws_iam_role.proxy_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/proxy/${var.environment}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "proxy_task_ecs_exec_msgs" {
  name = "${local.proxy_name_prefix}-ecs-exec-messages"
  role = aws_iam_role.proxy_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ]
      Resource = "*"
    }]
  })
}

# --- App Task Role ---
# Used by the running app container for EFS access and ECS Exec.
resource "aws_iam_role" "app_task" {
  name = "${local.name_prefix}-ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "app_task_efs" {
  name = "${local.name_prefix}-efs-access"
  role = aws_iam_role.app_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:DescribeMountTargets"
      ]
      Resource = aws_efs_file_system.vireo_asset_store.arn
    }]
  })
}

resource "aws_iam_role_policy" "app_task_ecs_exec_msgs" {
  name = "${local.name_prefix}-ecs-exec-messages"
  role = aws_iam_role.app_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ]
      Resource = "*"
    }]
  })
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================
# Security groups are created first without rules, then rules are added
# separately via aws_security_group_rule to avoid circular dependencies.

resource "aws_security_group" "public_alb" {
  name        = "${local.name_prefix}-public-alb-sg"
  description = "Security group for public ALB"
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${local.name_prefix}-public-alb-sg" })
}

resource "aws_security_group" "proxy" {
  name        = "${local.proxy_name_prefix}-sg"
  description = "Security group for proxy ECS tasks"
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${local.proxy_name_prefix}-sg" })
}

resource "aws_security_group" "internal_alb" {
  name        = "${local.name_prefix}-internal-alb-sg"
  description = "Security group for internal ALB"
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${local.name_prefix}-internal-alb-sg" })
}

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Security group for app ECS tasks"
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${local.name_prefix}-app-sg" })
}

# --- Public ALB rules ---
resource "aws_security_group_rule" "public_alb_ingress_https" {
  security_group_id = aws_security_group.public_alb.id
  type              = "ingress"
  description       = "HTTPS from internet"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public_alb_ingress_http" {
  security_group_id = aws_security_group.public_alb.id
  type              = "ingress"
  description       = "HTTP from internet (redirect to HTTPS)"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public_alb_egress_proxy" {
  security_group_id        = aws_security_group.public_alb.id
  type                     = "egress"
  description              = "HTTP to proxy"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.proxy.id
}

# --- Proxy rules ---
resource "aws_security_group_rule" "proxy_ingress_alb" {
  security_group_id        = aws_security_group.proxy.id
  type                     = "ingress"
  description              = "HTTP from public ALB"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public_alb.id
}

resource "aws_security_group_rule" "proxy_egress_internal_alb" {
  security_group_id        = aws_security_group.proxy.id
  type                     = "egress"
  description              = "HTTP to internal ALB"
  from_port                = 9000
  to_port                  = 9000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internal_alb.id
}

resource "aws_security_group_rule" "proxy_egress_https" {
  security_group_id = aws_security_group.proxy.id
  type              = "egress"
  description       = "HTTPS to AWS services (SSM, ECR, CloudWatch) and IdP"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# --- Internal ALB rules ---
resource "aws_security_group_rule" "internal_alb_ingress_proxy" {
  security_group_id        = aws_security_group.internal_alb.id
  type                     = "ingress"
  description              = "HTTP from proxy"
  from_port                = 9000
  to_port                  = 9000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.proxy.id
}

resource "aws_security_group_rule" "internal_alb_egress_app" {
  security_group_id        = aws_security_group.internal_alb.id
  type                     = "egress"
  description              = "HTTP to app"
  from_port                = 9000
  to_port                  = 9000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
}

# --- App rules ---
resource "aws_security_group_rule" "app_ingress_internal_alb" {
  security_group_id        = aws_security_group.app.id
  type                     = "ingress"
  description              = "HTTP from internal ALB"
  from_port                = 9000
  to_port                  = 9000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internal_alb.id
}

resource "aws_security_group_rule" "app_egress_all" {
  security_group_id = aws_security_group.app.id
  type              = "egress"
  description       = "All outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# =============================================================================
# PUBLIC APPLICATION LOAD BALANCER
# =============================================================================

resource "aws_lb" "public" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_alb.id]
  subnets            = var.public_subnet_ids

  dynamic "access_logs" {
    for_each = var.alb_access_logs_enabled ? [1] : []
    content {
      bucket  = aws_s3_bucket.alb_logs[0].bucket
      prefix  = "${var.project_name}-alb"
      enabled = true
    }
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-alb" })
}

# HTTPS listener — forwards to proxy target group
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.public.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.vireo.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.proxy.arn
  }

  tags = local.tags
}

# HTTP listener — redirect to HTTPS
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = local.tags
}

# Proxy target group — public ALB → proxy on port 8080
resource "aws_lb_target_group" "proxy" {
  name                 = "${local.proxy_name_prefix}-tg"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 15

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 60
    matcher             = "200-399"
  }

  tags = merge(local.tags, { Name = "${local.proxy_name_prefix}-tg" })
}

# =============================================================================
# INTERNAL APPLICATION LOAD BALANCER
# =============================================================================

resource "aws_lb" "internal" {
  name               = "${local.name_prefix}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb.id]
  subnets            = var.private_subnet_ids

  tags = merge(local.tags, { Name = "${local.name_prefix}-internal-alb" })
}

# Internal HTTP listener — forwards to app target group
resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 9000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = local.tags
}

# App target group — internal ALB → app on port 9000
resource "aws_lb_target_group" "app" {
  name                 = "${local.name_prefix}-app-tg"
  port                 = 9000
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 15

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 60
    matcher             = "200-399"
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-app-tg" })
}

# =============================================================================
# ROUTE53 PRIVATE HOSTED ZONE (internal ALB DNS)
# =============================================================================

resource "aws_route53_zone" "internal" {
  name    = var.internal_hosted_zone_name
  comment = "Private hosted zone for internal ALB"

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(local.tags, { Name = var.internal_hosted_zone_name })
}

resource "aws_route53_record" "internal_alb" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = var.internal_hosted_zone_name
  type    = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

# =============================================================================
# WAF WEB ACL (attached to public ALB only)
# =============================================================================

resource "aws_wafv2_web_acl" "vireo" {
  name        = "${local.name_prefix}-waf"
  description = "WAF for public ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimit"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "FORWARDED_IP"

        forwarded_ip_config {
          header_name       = "CF-Connecting-IP"
          fallback_behavior = "NO_MATCH"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  tags = local.tags
}

resource "aws_wafv2_web_acl_association" "vireo" {
  resource_arn = aws_lb.public.arn
  web_acl_arn  = aws_wafv2_web_acl.vireo.arn
}

# =============================================================================
# ACM CERTIFICATE (DNS Validation)
# =============================================================================

resource "aws_acm_certificate" "vireo" {
  domain_name       = var.public_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

# =============================================================================
# CLOUDWATCH LOG GROUPS
# =============================================================================

resource "aws_cloudwatch_log_group" "proxy" {
  name              = "/ecs/${var.environment}-${var.project_name}-proxy"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.environment}-${var.project_name}-app"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

# =============================================================================
# ECS TASK DEFINITIONS (externally managed)
# =============================================================================
# Task definitions are managed via external JSON files and deployed via CI/CD.
# The ECS services reference the latest active revision by family.
# Gated on deploy_ecs_services to allow initial infrastructure provisioning
# before task definitions are registered.

data "aws_ecs_task_definition" "proxy" {
  count           = var.deploy_ecs_services ? 1 : 0
  task_definition = var.proxy_task_family
}

data "aws_ecs_task_definition" "app" {
  count           = var.deploy_ecs_services ? 1 : 0
  task_definition = var.app_task_family
}

# =============================================================================
# ECS SERVICES
# =============================================================================

# Proxy service — public ALB → proxy container on port 8080
resource "aws_ecs_service" "proxy" {
  count                              = var.deploy_ecs_services ? 1 : 0
  name                               = "${local.proxy_name_prefix}-service"
  cluster                            = var.ecs_cluster_id
  task_definition                    = data.aws_ecs_task_definition.proxy[0].arn
  desired_count                      = var.proxy_task_count
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  platform_version                   = "1.4.0"
  enable_execute_command             = true

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.proxy.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.proxy.arn
    container_name   = var.proxy_container_name
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.https]
  tags       = local.tags

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
}

# App service — internal ALB → app container on port 9000
resource "aws_ecs_service" "app" {
  count                              = var.deploy_ecs_services ? 1 : 0
  name                               = "${local.name_prefix}-service"
  cluster                            = var.ecs_cluster_id
  task_definition                    = data.aws_ecs_task_definition.app[0].arn
  desired_count                      = var.vireo_task_count
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  platform_version                   = "1.4.0"
  enable_execute_command             = true

  network_configuration {
    subnets          = var.efs_one_zone_az != null ? [var.efs_one_zone_subnet_id] : var.private_subnet_ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_container_name
    container_port   = 9000
  }

  depends_on = [aws_lb_listener.internal_http, aws_efs_mount_target.vireo_asset_store]
  tags       = local.tags

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
}

# =============================================================================
# ECR REPOSITORY (shared for proxy and app images)
# =============================================================================

resource "aws_ecr_repository" "vireo" {
  name                 = "${local.name_prefix}-ecr"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.ecr_force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.tags, {
    Environment = "all"
    Name        = "${local.name_prefix}-ecr"
  })
}

# =============================================================================
# SSM PARAMETERS (Shibboleth SP Configuration — used by proxy task)
# Paths match the ARNs in the proxy task definition secrets/environment.
# =============================================================================

resource "aws_ssm_parameter" "shibboleth2_xml" {
  name        = "/${var.project_name}/proxy/${var.environment}/shibboleth2.xml"
  description = "Shibboleth SP shibboleth2.xml configuration"
  type        = "String"
  value       = var.shibboleth2_xml
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "shibboleth_attribute_map" {
  name        = "/${var.project_name}/proxy/${var.environment}/attribute-map.xml"
  description = "Shibboleth SP attribute-map.xml configuration"
  type        = "String"
  value       = var.shibboleth_attribute_map_xml
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "shibboleth_sp_cert" {
  name        = "/${var.project_name}/proxy/${var.environment}/sp-cert"
  description = "Shibboleth SP certificate (sp-cert.pem)"
  type        = "SecureString"
  value       = var.shibboleth_sp_cert
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "shibboleth_sp_key" {
  name        = "/${var.project_name}/proxy/${var.environment}/sp-key"
  description = "Shibboleth SP private key (sp-key.pem)"
  type        = "SecureString"
  value       = var.shibboleth_sp_key
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

# --- Proxy runtime config parameters ---
resource "aws_ssm_parameter" "proxy_server_name" {
  name        = "/${var.project_name}/proxy/${var.environment}/server-name"
  description = "Public hostname for the proxy (SERVER_NAME)"
  type        = "String"
  value       = var.public_domain
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "proxy_vireo_backend_url" {
  name        = "/${var.project_name}/proxy/${var.environment}/vireo-backend-url"
  description = "Internal ALB URL for backend (VIREO_BACKEND_URL)"
  type        = "String"
  value       = "http://${var.internal_hosted_zone_name}:9000"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "proxy_vireo_backend_host" {
  name        = "/${var.project_name}/proxy/${var.environment}/vireo-backend-host"
  description = "Internal ALB hostname for backend (VIREO_BACKEND_HOST)"
  type        = "String"
  value       = var.internal_hosted_zone_name
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

# =============================================================================
# SSM PARAMETERS (App configuration — used by app task)
# Paths match the ARNs in the app task definition secrets/environment.
# Values are placeholders — update via AWS Console or CLI after deployment.
# =============================================================================

resource "aws_ssm_parameter" "app_url" {
  name        = "/${var.project_name}/${var.environment}/app-url"
  description = "Public URL of the application (APP_URL)"
  type        = "String"
  value       = "https://${var.public_domain}"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_auth_service_url" {
  name        = "/${var.project_name}/${var.environment}/auth-service-url"
  description = "Frontend auth service URL (AUTH_SERVICE_URL)"
  type        = "String"
  value       = "window.location.protocol + '//' + window.location.host + window.location.base + '/auth'"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_local_authentication" {
  name        = "/${var.project_name}/${var.environment}/local-authentication"
  description = "Enable local authentication (LOCAL_AUTHENTICATION)"
  type        = "String"
  value       = "false"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_stomp_debug" {
  name        = "/${var.project_name}/${var.environment}/stomp-debug"
  description = "Enable STOMP WebSocket debug logging (STOMP_DEBUG)"
  type        = "String"
  value       = "false"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_spring_profiles_active" {
  name        = "/${var.project_name}/${var.environment}/spring-profiles-active"
  description = "Spring Boot active profiles"
  type        = "String"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_java_opts" {
  name        = "/${var.project_name}/${var.environment}/java-opts"
  description = "JVM options"
  type        = "String"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_db_url" {
  name        = "/${var.project_name}/${var.environment}/db-url"
  description = "Database JDBC URL"
  type        = "SecureString"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_db_username" {
  name        = "/${var.project_name}/${var.environment}/db-username"
  description = "Database username"
  type        = "SecureString"
  value       = var.db_username
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_db_password" {
  name        = "/${var.project_name}/${var.environment}/db-password"
  description = "Database password"
  type        = "SecureString"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_security_secret" {
  name        = "/${var.project_name}/${var.environment}/app-security-secret"
  description = "Application security secret"
  type        = "SecureString"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_cors_allow_access" {
  name        = "/${var.project_name}/${var.environment}/cors-allow-access"
  description = "CORS allowed origins"
  type        = "String"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_email_host" {
  name        = "/${var.project_name}/${var.environment}/email-host"
  description = "SMTP email host"
  type        = "String"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_email_username" {
  name        = "/${var.project_name}/${var.environment}/email-username"
  description = "SMTP email username"
  type        = "SecureString"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_email_password" {
  name        = "/${var.project_name}/${var.environment}/email-password"
  description = "SMTP email password"
  type        = "SecureString"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_email_from" {
  name        = "/${var.project_name}/${var.environment}/email-from"
  description = "Email from address"
  type        = "String"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_email_reply_to" {
  name        = "/${var.project_name}/${var.environment}/email-reply-to"
  description = "Email reply-to address"
  type        = "String"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_reporting_address" {
  name        = "/${var.project_name}/${var.environment}/reporting-address"
  description = "Reporting email address"
  type        = "String"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_jwt_secret" {
  name        = "/${var.project_name}/${var.environment}/jwt-secret"
  description = "JWT signing secret"
  type        = "SecureString"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_jwt_issuer" {
  name        = "/${var.project_name}/${var.environment}/jwt-issuer"
  description = "JWT issuer"
  type        = "String"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_jwt_duration" {
  name        = "/${var.project_name}/${var.environment}/jwt-duration"
  description = "JWT token duration"
  type        = "String"
  value       = "placeholder"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

# =============================================================================
# RDS DATABASE (conditional on deploy_database)
# =============================================================================

resource "aws_db_subnet_group" "vireo" {
  count      = var.deploy_database ? 1 : 0
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = local.tags
}

# DB security group — inbound 5432 from app SG only
resource "aws_security_group" "vireo_db" {
  count       = var.deploy_database ? 1 : 0
  name        = "${local.name_prefix}-db-sg"
  description = "Security group for Vireo RDS database"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from Vireo app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_secretsmanager_secret" "vireo_db_credentials" {
  count       = var.deploy_database ? 1 : 0
  name        = "${local.name_prefix}-db-credentials"
  description = "Database credentials for Vireo (manual rotation)"
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "vireo_db_credentials" {
  count     = var.deploy_database ? 1 : 0
  secret_id = aws_secretsmanager_secret.vireo_db_credentials[0].id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.vireo_db[0].result
    dbname   = var.db_name
    engine   = "postgres"
    host     = aws_db_instance.vireo[0].address
    port     = 5432
  })
}

resource "random_password" "vireo_db" {
  count   = var.deploy_database ? 1 : 0
  length  = 32
  special = false
}

resource "aws_db_instance" "vireo" {
  count = var.deploy_database ? 1 : 0

  identifier     = "${local.name_prefix}-db"
  engine         = "postgres"
  engine_version = "17"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.vireo_db[0].result

  multi_az               = var.db_multi_az
  db_subnet_group_name   = aws_db_subnet_group.vireo[0].name
  vpc_security_group_ids = [aws_security_group.vireo_db[0].id]

  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.db_deletion_protection
  skip_final_snapshot     = var.db_skip_final_snapshot

  tags = local.tags
}

# =============================================================================
# EFS ASSET STORE
# =============================================================================

# EFS security group — inbound 2049 from app SG only
resource "aws_security_group" "vireo_efs" {
  name        = "${local.name_prefix}-efs-sg"
  description = "Security group for Vireo EFS asset store"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from Vireo app"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_efs_file_system" "vireo_asset_store" {
  creation_token         = "${local.name_prefix}-asset-store"
  encrypted              = true
  performance_mode       = "generalPurpose"
  throughput_mode        = "bursting"
  availability_zone_name = var.efs_one_zone_az

  lifecycle_policy {
    transition_to_ia = "AFTER_14_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-asset-store" })
}

resource "aws_efs_mount_target" "vireo_asset_store" {
  count           = var.efs_one_zone_az != null ? 1 : length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.vireo_asset_store.id
  subnet_id       = var.efs_one_zone_az != null ? var.efs_one_zone_subnet_id : var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.vireo_efs.id]
}

resource "aws_efs_access_point" "vireo_asset_store" {
  file_system_id = aws_efs_file_system.vireo_asset_store.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/vireo-asset-store"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-asset-store-ap" })
}

# =============================================================================
# SES DOMAIN IDENTITY
# =============================================================================

resource "aws_ses_domain_identity" "vireo" {
  domain = var.ses_email_domain
}

# =============================================================================
# S3 BUCKET (ETL JOBS)
# =============================================================================

resource "aws_s3_bucket" "vireo_etl" {
  bucket        = var.vireo_s3_bucket_name
  force_destroy = var.s3_bucket_force_destroy
  tags          = local.tags
}

resource "aws_s3_bucket_versioning" "vireo_etl" {
  bucket = aws_s3_bucket.vireo_etl.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vireo_etl" {
  bucket = aws_s3_bucket.vireo_etl.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "vireo_etl" {
  bucket                  = aws_s3_bucket.vireo_etl.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# S3 BUCKET (ALB ACCESS LOGS — conditional on alb_access_logs_enabled)
# =============================================================================

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "alb_logs" {
  count         = var.alb_access_logs_enabled ? 1 : 0
  bucket        = "${local.name_prefix}-alb-logs"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  count                   = var.alb_access_logs_enabled ? 1 : 0
  bucket                  = aws_s3_bucket.alb_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  count  = var.alb_access_logs_enabled ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    id     = "expire-alb-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.alb_access_logs_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  count  = var.alb_access_logs_enabled ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = data.aws_elb_service_account.main.arn }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.alb_logs[0].arn}/${var.project_name}-alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}
