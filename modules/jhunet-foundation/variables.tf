variable "organization" {
  description = "The organization name (e.g., jhu)."
  type        = string
  default     = "jhu"
}

variable "project_name" {
  description = "A name for the project used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, stage, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod."
  }
}

variable "aws_region" {
  description = "The AWS region where resources reside."
  type        = string
  default     = "us-east-1"
}

# Networking — existing VPC and subnets on JHUnet
variable "vpc_id" {
  description = "The ID of the existing JHUnet-connected VPC."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of existing private subnet IDs for ECS tasks."
  type        = list(string)
}

# ECS Cluster
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster. Used for both the resource name and lookups."
  type        = string
}

variable "enable_container_insights" {
  description = "Whether to enable CloudWatch Container Insights on the ECS cluster."
  type        = bool
  default     = false
}

# Security
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
  description = "CIDR blocks allowed for outbound traffic from ECS tasks. Defaults to all traffic."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# IAM
variable "ecs_role_name" {
  description = "Name for the ECS IAM role (used as both task execution and task role)."
  type        = string
  default     = null
}

# Logging
variable "cloudwatch_log_group_name" {
  description = "Name for the CloudWatch log group. Defaults to /ecs/{project}-{env}."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs."
  type        = number
  default     = 30
}

# Tags
variable "tags" {
  description = "A map of tags to assign to all resources."
  type        = map(string)
  default     = {}
}
