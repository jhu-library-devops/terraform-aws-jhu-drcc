# =============================================================================
# DSPACE APP SERVICES MODULE OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# Target Groups
# -----------------------------------------------------------------------------
output "ui_target_group_arn" {
  description = "The ARN of the UI target group"
  value       = aws_lb_target_group.ui.arn
}

output "public_api_target_group_arn" {
  description = "The ARN of the public API target group"
  value       = aws_lb_target_group.public_api.arn
}

output "private_api_target_group_arn" {
  description = "The ARN of the private API target group"
  value       = aws_lb_target_group.private_api.arn
}

# -----------------------------------------------------------------------------
# Initialization Outputs
# -----------------------------------------------------------------------------
output "init_lambda_function_name" {
  description = "Name of the Lambda function for running initialization tasks"
  value       = var.enable_init_tasks ? aws_lambda_function.run_init_tasks[0].function_name : null
}

output "db_init_task_definition_arn" {
  description = "ARN of the database initialization task definition"
  value       = aws_ecs_task_definition.db_init.arn
}

output "solr_init_task_definition_arn" {
  description = "ARN of the Solr initialization task definition"
  value       = aws_ecs_task_definition.solr_init.arn
}

# -----------------------------------------------------------------------------
# DSpace Services
# -----------------------------------------------------------------------------
output "dspace_angular_service_arn" {
  description = "The ARN of the DSpace Angular ECS service"
  value       = aws_ecs_service.dspace_angular_service.id
}

output "dspace_angular_service_name" {
  description = "The name of the DSpace Angular ECS service"
  value       = aws_ecs_service.dspace_angular_service.name
}

output "dspace_api_service_arn" {
  description = "The ARN of the DSpace API ECS service"
  value       = aws_ecs_service.dspace_api_service.id
}

output "dspace_api_service_name" {
  description = "The name of the DSpace API ECS service"
  value       = aws_ecs_service.dspace_api_service.name
}

output "dspace_api_task_definition_arn" {
  description = "ARN of the DSpace API task definition (Terraform-managed or external)"
  value       = var.use_external_task_definitions ? var.dspace_api_task_def_arn : aws_ecs_task_definition.dspace_api[0].arn
}

output "dspace_api_task_definition_family" {
  description = "Family name of the DSpace API task definition (null when using external task definitions)"
  value       = var.use_external_task_definitions ? null : aws_ecs_task_definition.dspace_api[0].family
}

output "dspace_angular_task_definition_arn" {
  description = "ARN of the DSpace Angular task definition (Terraform-managed or external)"
  value       = var.use_external_task_definitions ? var.dspace_angular_task_def_arn : aws_ecs_task_definition.dspace_angular[0].arn
}

output "dspace_angular_task_definition_family" {
  description = "Family name of the DSpace Angular task definition (null when using external task definitions)"
  value       = var.use_external_task_definitions ? null : aws_ecs_task_definition.dspace_angular[0].family
}

output "dspace_jobs_task_definition_arn" {
  description = "ARN of the DSpace Jobs task definition (Terraform-managed or external)"
  value       = var.use_external_task_definitions ? var.dspace_jobs_task_def_arn : aws_ecs_task_definition.dspace_jobs[0].arn
}

output "dspace_jobs_task_definition_family" {
  description = "Family name of the DSpace Jobs task definition (null when using external task definitions)"
  value       = var.use_external_task_definitions ? null : aws_ecs_task_definition.dspace_jobs[0].family
}

output "dspace_scheduled_jobs" {
  description = "List of DSpace scheduled job names"
  value       = keys(local.dspace_jobs)
}

# -----------------------------------------------------------------------------
# Storage Resources
# -----------------------------------------------------------------------------

output "dspace_asset_store_bucket_name" {
  description = "The name of the DSpace asset store S3 bucket"
  value       = aws_s3_bucket.dspace_asset_store.bucket
}

output "dspace_asset_store_bucket_arn" {
  description = "The ARN of the DSpace asset store S3 bucket"
  value       = aws_s3_bucket.dspace_asset_store.arn
}

# -----------------------------------------------------------------------------
# CI/CD Integration
# -----------------------------------------------------------------------------
output "github_actions_role_arn" {
  description = "The ARN of the GitHub Actions deployment role"
  value       = aws_iam_role.github_actions_role.arn
}

output "github_actions_test_role_arn" {
  description = "The ARN of the GitHub Actions test role"
  value       = aws_iam_role.github_actions_test_role.arn
}

output "eventbridge_ecs_role_arn" {
  description = "The ARN of the EventBridge ECS execution role"
  value       = aws_iam_role.eventbridge_ecs_role.arn
}

# -----------------------------------------------------------------------------
# EFS Outputs (DSpace config EFS removed, returning null for compatibility)
# -----------------------------------------------------------------------------
output "dspace_config_efs_id" {
  description = "The ID of the DSpace config EFS file system (deprecated)"
  value       = null
}

output "dspace_config_efs_arn" {
  description = "The ARN of the DSpace config EFS file system (deprecated)"
  value       = null
}

output "dspace_config_efs_dns_name" {
  description = "The DNS name of the DSpace config EFS file system (deprecated)"
  value       = null
}

# -----------------------------------------------------------------------------
# Monitoring and Alerting
# -----------------------------------------------------------------------------
output "dspace_alerts_topic_arn" {
  description = "The ARN of the DSpace alerts SNS topic"
  value       = aws_sns_topic.dspace_alerts.arn
}

# -----------------------------------------------------------------------------
# CloudWatch Dashboard
# -----------------------------------------------------------------------------
output "dashboard_name" {
  description = "The name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.dspace_application.dashboard_name
}

output "dashboard_url" {
  description = "The URL to access the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.dspace_application.dashboard_name}"
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------
output "db_instance_id" {
  description = "The ID of the RDS instance"
  value       = var.deploy_database ? aws_db_instance.main[0].id : null
}

output "db_instance_identifier" {
  description = "The identifier of the RDS instance"
  value       = var.deploy_database ? aws_db_instance.main[0].identifier : null
}

output "db_instance_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = var.deploy_database ? aws_db_instance.main[0].endpoint : null
}

output "db_credentials_secret_arn" {
  description = "The ARN of the database credentials secret"
  value       = local.db_secret_arn_final
}
