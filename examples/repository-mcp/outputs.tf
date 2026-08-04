output "service_endpoint" {
  description = "Public Repository MCP endpoint."
  value       = module.repository_mcp.public_endpoint
}

output "ecs_service_name" {
  description = "Repository MCP ECS service name."
  value       = module.repository_mcp.ecs_service_name
}

output "task_security_group_id" {
  description = "Repository MCP task security group ID."
  value       = module.repository_mcp.task_security_group_id
}

output "log_group_name" {
  description = "Repository MCP CloudWatch log group name."
  value       = module.repository_mcp.log_group_name
}
