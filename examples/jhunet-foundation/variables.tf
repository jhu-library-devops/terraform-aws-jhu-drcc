variable "organization" {
  description = "The organization name."
  type        = string
  default     = "jhu"
}

variable "project_name" {
  description = "Project name used in resource naming."
  type        = string
  default     = "jhunet-internal"
}

variable "environment" {
  description = "The deployment environment (dev, stage, prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "The ID of the existing JHUnet-connected VPC."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of existing private subnet IDs."
  type        = list(string)
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "container_insights_value" {
  description = "Container Insights setting: disabled, enabled, or enhanced."
  type        = string
  default     = "disabled"
}

variable "execute_command_logging" {
  description = "Logging configuration for ECS Exec."
  type        = string
  default     = null
}

variable "service_connect_namespace_arn" {
  description = "ARN of the Cloud Map namespace for Service Connect defaults."
  type        = string
  default     = null
}

variable "ecs_security_group_name" {
  description = "Name for the ECS tasks security group."
  type        = string
  default     = null
}

variable "ecs_security_group_description" {
  description = "Description for the ECS tasks security group."
  type        = string
  default     = null
}

variable "egress_cidr_blocks" {
  description = "CIDR blocks allowed for outbound traffic from ECS tasks."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ecs_role_name" {
  description = "Name for the ECS IAM role."
  type        = string
  default     = null
}

variable "cloudwatch_log_group_name" {
  description = "Name for the CloudWatch log group."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs."
  type        = number
  default     = 30
}

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
  default     = {}
}
