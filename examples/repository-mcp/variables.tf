variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "organization" {
  description = "Organization identifier."
  type        = string
  default     = "jhu"
}

variable "project_name" {
  description = "Project identifier."
  type        = string
  default     = "repository-mcp"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "resource_name_prefix" {
  description = "Optional legacy-compatible resource name prefix."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "Existing foundation VPC ID."
  type        = string
}

variable "vpc_cidr_block" {
  description = "Existing foundation VPC CIDR block."
  type        = string
}

variable "private_subnet_ids" {
  description = "Existing foundation private subnet IDs."
  type        = list(string)
}

variable "ecs_cluster_id" {
  description = "Existing foundation ECS cluster ID."
  type        = string
}

variable "ecs_cluster_name" {
  description = "Existing foundation ECS cluster name."
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "Existing foundation ECS task execution role ARN."
  type        = string
}

variable "ecs_task_role_arn" {
  description = "Existing foundation ECS task role ARN."
  type        = string
}

variable "public_alb_https_listener_arn" {
  description = "Existing foundation public HTTPS listener ARN."
  type        = string
}

variable "public_alb_security_group_id" {
  description = "Existing foundation public ALB security group ID."
  type        = string
}

variable "public_alb_arn_suffix" {
  description = "Existing foundation public ALB ARN suffix."
  type        = string
}

variable "public_alb_certificate_arn" {
  description = "Optional additional ACM certificate ARN for the MCP hostname."
  type        = string
  default     = null
}

variable "jscholarship_solr_security_group_id" {
  description = "Security group ID attached to the configured JScholarship Solr endpoint."
  type        = string
}

variable "jscholarship_api_security_group_id" {
  description = "JScholarship API endpoint security group ID."
  type        = string
}

variable "jhrdr_solr_security_group_id" {
  description = "Optional JHRDR Solr security group ID."
  type        = string
  default     = null
}

variable "jhrdr_api_security_group_id" {
  description = "Optional JHRDR API security group ID."
  type        = string
  default     = null
}

variable "use_external_task_definitions" {
  description = "Use an externally managed MCP task definition."
  type        = bool
  default     = false
}

variable "mcp_task_def_arn" {
  description = "External MCP task definition ARN."
  type        = string
  default     = null
}

variable "mcp_image" {
  description = "Repository MCP container image URI."
  type        = string
  default     = null
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 1024
}

variable "capacity_provider" {
  description = "Fargate capacity provider."
  type        = string
  default     = "FARGATE"
}

variable "public_hostname" {
  description = "Public MCP hostname."
  type        = string
}

variable "listener_rule_priority" {
  description = "Unique public ALB listener-rule priority."
  type        = number
}

variable "jscholarship_solr_url" {
  description = "Internal JScholarship Solr search URL."
  type        = string
}

variable "jscholarship_api_url" {
  description = "Internal JScholarship API URL."
  type        = string
}

variable "jscholarship_public_url" {
  description = "Public JScholarship base URL."
  type        = string
}

variable "jhrdr_solr_url" {
  description = "Internal JHRDR Solr URL."
  type        = string
  default     = ""
}

variable "jhrdr_api_url" {
  description = "Internal JHRDR API URL."
  type        = string
  default     = ""
}

variable "jhrdr_public_url" {
  description = "Public JHRDR base URL."
  type        = string
  default     = ""
}

variable "service_desired_count" {
  description = "Initial MCP task count."
  type        = number
  default     = 1
}

variable "service_min_count" {
  description = "Minimum autoscaling task count."
  type        = number
  default     = 1
}

variable "service_max_count" {
  description = "Maximum autoscaling task count."
  type        = number
  default     = 2
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 90
}

variable "alarm_sns_topic_arn" {
  description = "Optional SNS topic ARN for alarms."
  type        = string
  default     = null
}
