output "ecs_service_name" {
  description = "Name of the Repository MCP ECS service."
  value       = aws_ecs_service.mcp.name
}

output "ecs_service_arn" {
  description = "ARN of the Repository MCP ECS service."
  value       = aws_ecs_service.mcp.id
}

output "mcp_task_definition_arn" {
  description = "ARN of the external or Terraform-managed Repository MCP task definition."
  value       = local.mcp_task_definition_arn
}

output "mcp_task_definition_family" {
  description = "Family of the Terraform-managed task definition, or null in external mode."
  value       = var.use_external_task_definitions ? null : aws_ecs_task_definition.mcp[0].family
}

output "task_security_group_id" {
  description = "Security group ID attached to Repository MCP tasks."
  value       = aws_security_group.mcp.id
}

output "target_group_arn" {
  description = "ARN of the Repository MCP ALB target group."
  value       = aws_lb_target_group.mcp.arn
}

output "log_group_name" {
  description = "CloudWatch log group name for Repository MCP containers."
  value       = aws_cloudwatch_log_group.mcp.name
}

output "public_endpoint" {
  description = "Public MCP protocol endpoint."
  value       = "https://${lower(var.public_hostname)}/mcp"
}
