# =============================================================================
# VIREO APP SERVICES MODULE - OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# Public ALB
# -----------------------------------------------------------------------------

output "alb_arn" {
  description = "The ARN of the public ALB"
  value       = aws_lb.public.arn
}

output "alb_dns_name" {
  description = "The DNS name of the public ALB (use for Route53 CNAME/alias)"
  value       = aws_lb.public.dns_name
}

output "alb_zone_id" {
  description = "The hosted zone ID of the public ALB (for Route53 alias records)"
  value       = aws_lb.public.zone_id
}

# -----------------------------------------------------------------------------
# Internal ALB
# -----------------------------------------------------------------------------

output "internal_alb_arn" {
  description = "The ARN of the internal ALB"
  value       = aws_lb.internal.arn
}

output "internal_alb_dns_name" {
  description = "The DNS name of the internal ALB"
  value       = aws_lb.internal.dns_name
}

# -----------------------------------------------------------------------------
# DNS
# -----------------------------------------------------------------------------

output "internal_hosted_zone_id" {
  description = "The ID of the Route53 private hosted zone for the internal ALB"
  value       = aws_route53_zone.internal.zone_id
}

output "internal_hosted_zone_name" {
  description = "The name of the Route53 private hosted zone for the internal ALB"
  value       = aws_route53_zone.internal.name
}

# -----------------------------------------------------------------------------
# WAF
# -----------------------------------------------------------------------------

output "waf_web_acl_arn" {
  description = "The ARN of the WAFv2 Web ACL attached to the public ALB"
  value       = aws_wafv2_web_acl.vireo.arn
}

# -----------------------------------------------------------------------------
# IAM Roles
# -----------------------------------------------------------------------------

output "proxy_task_execution_role_arn" {
  description = "The ARN of the proxy ECS task execution role"
  value       = aws_iam_role.proxy_task_execution.arn
}

output "proxy_task_role_arn" {
  description = "The ARN of the proxy ECS task role"
  value       = aws_iam_role.proxy_task.arn
}

output "app_task_execution_role_arn" {
  description = "The ARN of the app ECS task execution role"
  value       = aws_iam_role.app_task_execution.arn
}

output "app_task_role_arn" {
  description = "The ARN of the app ECS task role"
  value       = aws_iam_role.app_task.arn
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------

output "public_alb_security_group_id" {
  description = "The ID of the public ALB security group"
  value       = aws_security_group.public_alb.id
}

output "proxy_security_group_id" {
  description = "The ID of the proxy ECS security group"
  value       = aws_security_group.proxy.id
}

output "app_security_group_id" {
  description = "The ID of the app ECS security group"
  value       = aws_security_group.app.id
}

# -----------------------------------------------------------------------------
# ECS Services
# -----------------------------------------------------------------------------

output "proxy_service_arn" {
  description = "The ARN of the proxy ECS service (null when deploy_ecs_services is false)"
  value       = var.deploy_ecs_services ? aws_ecs_service.proxy[0].id : null
}

output "proxy_service_name" {
  description = "The name of the proxy ECS service (null when deploy_ecs_services is false)"
  value       = var.deploy_ecs_services ? aws_ecs_service.proxy[0].name : null
}

output "app_service_arn" {
  description = "The ARN of the app ECS service (null when deploy_ecs_services is false)"
  value       = var.deploy_ecs_services ? aws_ecs_service.app[0].id : null
}

output "app_service_name" {
  description = "The name of the app ECS service (null when deploy_ecs_services is false)"
  value       = var.deploy_ecs_services ? aws_ecs_service.app[0].name : null
}

# -----------------------------------------------------------------------------
# Target Groups
# -----------------------------------------------------------------------------

output "proxy_target_group_arn" {
  description = "The ARN of the proxy ALB target group"
  value       = aws_lb_target_group.proxy.arn
}

output "app_target_group_arn" {
  description = "The ARN of the app ALB target group (internal)"
  value       = aws_lb_target_group.app.arn
}

# -----------------------------------------------------------------------------
# Database (conditional on var.deploy_database)
# -----------------------------------------------------------------------------

output "db_instance_endpoint" {
  description = "The endpoint of the RDS instance (null when deploy_database is false)"
  value       = var.deploy_database ? aws_db_instance.vireo[0].endpoint : null
  sensitive   = true
}

output "db_credentials_secret_arn" {
  description = "The ARN of the database credentials secret (null when deploy_database is false)"
  value       = var.deploy_database ? aws_secretsmanager_secret.vireo_db_credentials[0].arn : null
}

# -----------------------------------------------------------------------------
# Storage - EFS
# -----------------------------------------------------------------------------

output "efs_file_system_id" {
  description = "The ID of the EFS file system for the asset store"
  value       = aws_efs_file_system.vireo_asset_store.id
}

output "efs_access_point_id" {
  description = "The ID of the EFS access point"
  value       = aws_efs_access_point.vireo_asset_store.id
}

# -----------------------------------------------------------------------------
# Storage - S3 (ETL)
# -----------------------------------------------------------------------------

output "s3_bucket_name" {
  description = "The name of the S3 bucket for ETL jobs"
  value       = aws_s3_bucket.vireo_etl.bucket
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket for ETL jobs"
  value       = aws_s3_bucket.vireo_etl.arn
}

# -----------------------------------------------------------------------------
# ECR Repository
# -----------------------------------------------------------------------------

output "ecr_repository_url" {
  description = "The URL of the ECR repository (shared for proxy and app images)"
  value       = aws_ecr_repository.vireo.repository_url
}

output "ecr_repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.vireo.arn
}

# -----------------------------------------------------------------------------
# ACM Certificate
# -----------------------------------------------------------------------------

output "certificate_arn" {
  description = "The ARN of the ACM certificate for the public domain"
  value       = aws_acm_certificate.vireo.arn
}

output "certificate_validation_records" {
  description = "DNS validation records to create for the ACM certificate"
  value = {
    for dvo in aws_acm_certificate.vireo.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

# -----------------------------------------------------------------------------
# SES
# -----------------------------------------------------------------------------

output "ses_domain_identity_arn" {
  description = "The ARN of the SES domain identity"
  value       = aws_ses_domain_identity.vireo.arn
}

output "ses_verification_token" {
  description = "The verification token for the SES domain identity. Create a TXT record named _amazonses.<domain> with this value."
  value       = aws_ses_domain_identity.vireo.verification_token
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------

output "proxy_log_group_name" {
  description = "The name of the proxy CloudWatch log group"
  value       = aws_cloudwatch_log_group.proxy.name
}

output "app_log_group_name" {
  description = "The name of the app CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.name
}
