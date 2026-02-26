variable "organization" {
  description = "The organization name"
  type        = string
  default     = "jhu"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "dspace"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "public_domain" {
  description = "Public domain name"
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "dspace"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "dspaceuser"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "solr_node_count" {
  description = "Number of Solr nodes"
  type        = number
}

variable "deploy_zookeeper" {
  description = "Deploy Zookeeper cluster"
  type        = bool
}

variable "zookeeper_task_count" {
  description = "Number of Zookeeper nodes"
  type        = number
}

variable "solr_cpu" {
  description = "Solr task CPU units"
  type        = string
}

variable "solr_memory" {
  description = "Solr task memory in MB"
  type        = string
}

variable "dspace_angular_task_def_arn" {
  description = "External task definition ARN for Angular UI"
  type        = string
  default     = null
}

variable "dspace_api_task_def_arn" {
  description = "External task definition ARN for REST API"
  type        = string
  default     = null
}

variable "dspace_jobs_task_def_arn" {
  description = "External task definition ARN for background jobs"
  type        = string
  default     = null
}

variable "dspace_angular_task_count" {
  description = "Number of Angular UI tasks"
  type        = number
  default     = 1
}

variable "dspace_api_task_count" {
  description = "Number of API tasks"
  type        = number
  default     = 1
}

# Initialization Configuration
variable "enable_init_tasks" {
  description = "Enable Lambda function for running initialization tasks"
  type        = bool
  default     = false
}

variable "dspace_api_image" {
  description = "Docker image for DSpace API (used for initialization)"
  type        = string
  default     = null
}

variable "dspace_asset_store_bucket_name" {
  description = "The name of the S3 bucket for DSpace asset store"
  type        = string
}

variable "alarm_notification_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}
