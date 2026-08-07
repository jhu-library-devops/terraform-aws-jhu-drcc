# VPC and Networking
output "vpc_id" {
  description = "The ID of the JHUnet-connected VPC"
  value       = var.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  value       = var.private_subnet_ids
}

# ECS Cluster
output "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

# Security Groups
output "ecs_security_group_id" {
  description = "The ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

# IAM Role
output "ecs_role_arn" {
  description = "The ARN of the ECS role (used as both execution and task role)"
  value       = aws_iam_role.ecs_role.arn
}

output "ecs_role_name" {
  description = "The name of the ECS role"
  value       = aws_iam_role.ecs_role.name
}

# Logging
output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group for ECS tasks"
  value       = aws_cloudwatch_log_group.ecs_tasks.name
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group for ECS tasks"
  value       = aws_cloudwatch_log_group.ecs_tasks.arn
}
