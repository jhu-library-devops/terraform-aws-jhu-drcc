output "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  value       = module.jhunet_foundation.ecs_cluster_id
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = module.jhunet_foundation.ecs_cluster_arn
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.jhunet_foundation.ecs_cluster_name
}

output "ecs_security_group_id" {
  description = "The ID of the ECS tasks security group"
  value       = module.jhunet_foundation.ecs_security_group_id
}

output "ecs_role_arn" {
  description = "The ARN of the ECS role"
  value       = module.jhunet_foundation.ecs_role_arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = module.jhunet_foundation.cloudwatch_log_group_name
}
