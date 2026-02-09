# Variables for the DSpace App Services Module

# Basic Configuration
variable "organization" {
  description = "The organization name (e.g., jhu)."
  type        = string
  default     = "jhu"
}

variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "dspace"
}

variable "environment" {
  description = "The deployment environment (e.g., stage, prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Infrastructure Dependencies (passed from foundation module)
variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS services."
  type        = list(string)
}

variable "ecs_cluster_id" {
  description = "The ID of the ECS cluster."
  type        = string
}

variable "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster."
  type        = string
}

variable "ecs_security_group_id" {
  description = "The ID of the ECS security group."
  type        = string
}

variable "alb_https_listener_arn" {
  description = "The ARN of the public ALB HTTPS listener."
  type        = string
}

variable "private_alb_listener_arn" {
  description = "The ARN of the private ALB HTTP listener."
  type        = string
}

# DSpace Angular UI Configuration
variable "dspace_angular_task_def_arn" {
  description = "The ARN of the ECS Task Definition for DSpace Angular."
  type        = string
  default     = null
}

variable "dspace_angular_task_count" {
  description = "The number of DSpace Angular tasks to run."
  type        = number
  default     = 1
}

# DSpace API Configuration
variable "dspace_api_task_def_arn" {
  description = "The ARN of the ECS Task Definition for DSpace Api."
  type        = string
  default     = null
}

variable "dspace_api_task_count" {
  description = "The number of DSpace API tasks to run."
  type        = number
  default     = 1
}

# DSpace Jobs Configuration
variable "dspace_jobs_task_def_arn" {
  description = "The ARN of the ECS Task Definition for DSpace Jobs."
  type        = string
  default     = null
}

# Monitoring Configuration
variable "alarm_notification_email" {
  description = "Email address for CloudWatch alarm notifications."
  type        = string
}

# DSpace Container Resource Allocation
variable "dspace_angular_cpu" {
  description = "The CPU units for the DSpace Angular task."
  type        = number
  default     = 512
}

variable "dspace_angular_memory" {
  description = "The memory (in MiB) for the DSpace Angular task."
  type        = number
  default     = 1024
}

variable "dspace_api_cpu" {
  description = "The CPU units for the DSpace API task."
  type        = number
  default     = 1024
}

variable "dspace_api_memory" {
  description = "The memory (in MiB) for the DSpace API task."
  type        = number
  default     = 2048
}

variable "dspace_jobs_cpu" {
  description = "The CPU units for the DSpace Jobs task."
  type        = number
  default     = 512
}

variable "dspace_jobs_memory" {
  description = "The memory (in MiB) for the DSpace Jobs task."
  type        = number
  default     = 1024
}

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "dspace_asset_store_bucket_name" {
  description = "The name of the S3 bucket for DSpace asset store."
  type        = string
}

variable "s3_bucket_force_destroy" {
  description = "Whether to allow force destruction of the S3 bucket (opposite of deletion protection)."
  type        = bool
  default     = true
}

variable "use_external_task_definitions" {
  description = "Whether to use externally managed task definitions instead of module-generated ones."
  type        = bool
  default     = true
}

variable "deploy_admin_service" {
  description = "Whether to deploy the admin service"
  type        = bool
  default     = false
}
