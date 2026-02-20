# Solr Service Outputs
output "solr_target_group_arn" {
  description = "The ARN of the Solr target group"
  value       = aws_lb_target_group.solr.arn
}

output "solr_service_arns" {
  description = "The ARNs of the Solr ECS services"
  value       = aws_ecs_service.solr_fargate_service[*].id
}

output "solr_service_names" {
  description = "The names of the Solr ECS services"
  value       = aws_ecs_service.solr_fargate_service[*].name
}

output "solr_service_arn" {
  description = "The ARN of the first Solr ECS service"
  value       = length(aws_ecs_service.solr_fargate_service) > 0 ? aws_ecs_service.solr_fargate_service[0].id : null
}

output "solr_service_name" {
  description = "The name of the first Solr ECS service"
  value       = length(aws_ecs_service.solr_fargate_service) > 0 ? aws_ecs_service.solr_fargate_service[0].name : null
}

output "zookeeper_1_service_arn" {
  description = "The ARN of the first Zookeeper ECS service"
  value       = var.deploy_zookeeper && !var.use_external_task_definitions && var.zookeeper_task_count >= 1 ? aws_ecs_service.zookeeper_fargate_service[0].id : null
}

output "zookeeper_1_service_name" {
  description = "The name of the first Zookeeper ECS service"
  value       = var.deploy_zookeeper && !var.use_external_task_definitions && var.zookeeper_task_count >= 1 ? aws_ecs_service.zookeeper_fargate_service[0].name : null
}

output "zookeeper_2_service_arn" {
  description = "The ARN of the second Zookeeper ECS service"
  value       = var.deploy_zookeeper && !var.use_external_task_definitions && var.zookeeper_task_count >= 2 ? aws_ecs_service.zookeeper_fargate_service[1].id : null
}

output "zookeeper_2_service_name" {
  description = "The name of the second Zookeeper ECS service"
  value       = var.deploy_zookeeper && !var.use_external_task_definitions && var.zookeeper_task_count >= 2 ? aws_ecs_service.zookeeper_fargate_service[1].name : null
}

output "zookeeper_3_service_arn" {
  description = "The ARN of the third Zookeeper ECS service"
  value       = var.deploy_zookeeper && !var.use_external_task_definitions && var.zookeeper_task_count >= 3 ? aws_ecs_service.zookeeper_fargate_service[2].id : null
}

output "zookeeper_3_service_name" {
  description = "The name of the third Zookeeper ECS service"
  value       = var.deploy_zookeeper && !var.use_external_task_definitions && var.zookeeper_task_count >= 3 ? aws_ecs_service.zookeeper_fargate_service[2].name : null
}

output "zookeeper_service_arn" {
  description = "The ARN of the Zookeeper ECS service"
  value       = var.deploy_zookeeper && !var.use_external_task_definitions ? aws_ecs_service.zookeeper_fargate_service[0].id : null
}

output "zookeeper_service_name" {
  description = "The name of the Zookeeper ECS service"
  value       = var.deploy_zookeeper && !var.use_external_task_definitions ? aws_ecs_service.zookeeper_fargate_service[0].name : null
}

# ECR Repository Outputs
output "ecr_repository_urls" {
  description = "A map of ECR repository names to their URLs"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.repository_url }
}

# Secrets Outputs
output "zookeeper_secret_arn" {
  description = "The ARN of the Secrets Manager secret for the Zookeeper host"
  value       = local.zk_secret_arn_final
}

# Service Discovery Outputs
output "service_discovery_namespace_id" {
  description = "The ID of the service discovery namespace"
  value       = var.service_discovery_namespace_id
}

output "service_discovery_namespace_name" {
  description = "The name of the service discovery namespace"
  value       = var.service_discovery_namespace_name
}

# Monitoring Outputs
output "cloudwatch_dashboard_name" {
  description = "The name of the CloudWatch dashboard"
  value       = var.enable_enhanced_monitoring ? aws_cloudwatch_dashboard.solr[0].dashboard_name : null
}

output "cloudwatch_dashboard_url" {
  description = "The URL of the CloudWatch dashboard"
  value       = var.enable_enhanced_monitoring ? "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.solr[0].dashboard_name}" : null
}

# EFS Outputs
output "solr_data_efs_id" {
  description = "The ID of the Solr data EFS file system"
  value       = aws_efs_file_system.solr_data.id
}

output "solr_data_efs_access_point_id" {
  description = "The ID of the Solr data EFS access point"
  value       = aws_efs_access_point.solr_data.id
}

output "solr_node_efs_access_point_ids" {
  description = "The IDs of the individual Solr node EFS access points"
  value       = aws_efs_access_point.solr_node[*].id
}

output "solr_node_efs_access_points" {
  description = "Map of Solr node names to their EFS access point IDs and paths"
  value = {
    for i in range(var.solr_node_count) : "solr-${i + 1}" => {
      access_point_id = aws_efs_access_point.solr_node[i].id
      path            = "/solr-data/solr-${i + 1}"
    }
  }
}

output "solr_efs_id" {
  description = "The ID of the Solr data EFS file system (alias)"
  value       = aws_efs_file_system.solr_data.id
}

output "solr_efs_arn" {
  description = "The ARN of the Solr data EFS file system"
  value       = aws_efs_file_system.solr_data.arn
}

output "solr_efs_dns_name" {
  description = "The DNS name of the Solr data EFS file system"
  value       = aws_efs_file_system.solr_data.dns_name
}

output "zookeeper_data_efs_id" {
  description = "The ID of the Zookeeper data EFS file system"
  value       = var.deploy_zookeeper ? aws_efs_file_system.zookeeper_data[0].id : null
}

output "zookeeper_data_efs_access_point_id" {
  description = "The ID of the Zookeeper data EFS access point"
  value       = var.deploy_zookeeper ? aws_efs_access_point.zookeeper_data[0].id : null
}

# -----------------------------------------------------------------------------
# Task Definition Outputs
# -----------------------------------------------------------------------------

output "solr_task_definition_arns" {
  description = "List of ARNs for Solr node task definitions (Terraform-managed or external)"
  value       = var.use_external_task_definitions ? var.solr_task_def_arns : aws_ecs_task_definition.solr_node[*].arn
}

output "solr_task_definition_families" {
  description = "List of family names for Solr node task definitions (empty when using external task definitions)"
  value       = var.use_external_task_definitions ? [] : aws_ecs_task_definition.solr_node[*].family
}

output "zookeeper_task_definition_arns" {
  description = "List of ARNs for Zookeeper node task definitions (Terraform-managed or external)"
  value       = var.deploy_zookeeper && !var.use_external_task_definitions ? aws_ecs_task_definition.zookeeper_node[*].arn : (var.use_external_task_definitions ? var.zookeeper_task_def_arns : [])
}

output "zookeeper_task_definition_families" {
  description = "List of family names for Zookeeper node task definitions (empty when using external task definitions)"
  value       = var.deploy_zookeeper && !var.use_external_task_definitions ? aws_ecs_task_definition.zookeeper_node[*].family : []
}
