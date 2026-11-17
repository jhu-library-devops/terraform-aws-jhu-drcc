# =============================================================================
# VIREO APP SERVICES MODULE - VARIABLES
# =============================================================================

# -----------------------------------------------------------------------------
# Identity
# -----------------------------------------------------------------------------

variable "organization" {
  description = "The organization name."
  type        = string
}

variable "environment" {
  description = "The deployment environment."
  type        = string
}

variable "project_name" {
  description = "The project name used in resource naming and SSM parameter paths."
  type        = string
  default     = "vireo"
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "The ID of the shared VPC."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs (for ALB placement)."
  type        = list(string)
}

# -----------------------------------------------------------------------------
# Cluster
# -----------------------------------------------------------------------------

variable "ecs_cluster_id" {
  description = "The ID of the shared ECS cluster."
  type        = string
}

variable "deploy_ecs_services" {
  description = "Whether to create the ECS services. Set to false for initial infrastructure provisioning before task definitions are registered."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Domain
# -----------------------------------------------------------------------------

variable "public_domain" {
  description = "The public domain name for Vireo (used for ALB host-based routing)."
  type        = string
}

variable "ses_email_domain" {
  description = "The domain to register as an SES identity for sending email."
  type        = string
}

variable "internal_hosted_zone_name" {
  description = "The name of the Route53 private hosted zone for the internal ALB (e.g. vireo.internal)."
  type        = string
}

# -----------------------------------------------------------------------------
# ECS Tasks
# -----------------------------------------------------------------------------

variable "proxy_task_family" {
  description = "The ECS task definition family name for the proxy (externally managed). Required when deploy_ecs_services is true."
  type        = string
  default     = null
}

variable "proxy_container_name" {
  description = "The container name in the proxy task definition. Required when deploy_ecs_services is true."
  type        = string
  default     = null
}

variable "app_task_family" {
  description = "The ECS task definition family name for the Vireo app (externally managed). Required when deploy_ecs_services is true."
  type        = string
  default     = null
}

variable "app_container_name" {
  description = "The container name in the Vireo app task definition. Required when deploy_ecs_services is true."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Scaling
# -----------------------------------------------------------------------------

variable "proxy_task_count" {
  description = "The number of proxy tasks to run."
  type        = number
  default     = 1
}

variable "vireo_task_count" {
  description = "The number of Vireo tasks to run."
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------------

variable "deploy_database" {
  description = "Whether to deploy a new RDS PostgreSQL database."
  type        = bool
  default     = true
}

variable "db_instance_class" {
  description = "The instance class for the RDS database."
  type        = string
  default     = "db.t4g.medium"
}

variable "db_multi_az" {
  description = "Specifies if the RDS instance is multi-AZ."
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "The days to retain backups for."
  type        = number
  default     = 1
}

variable "db_deletion_protection" {
  description = "If the DB instance should have deletion protection enabled."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before deletion."
  type        = bool
  default     = true
}

variable "db_name" {
  description = "The name of the database."
  type        = string
  default     = "vireo"
}

variable "db_username" {
  description = "The username for the database."
  type        = string
  default     = "vireo"
}

# -----------------------------------------------------------------------------
# Storage
# -----------------------------------------------------------------------------

variable "vireo_s3_bucket_name" {
  description = "The name of the S3 bucket for Vireo ETL jobs."
  type        = string
}

variable "s3_bucket_force_destroy" {
  description = "Whether to allow force destruction of the S3 bucket."
  type        = bool
  default     = false
}

variable "efs_one_zone_az" {
  description = "Availability zone for One Zone EFS storage. Set to null for Multi-AZ (default)."
  type        = string
  default     = null
}

variable "efs_one_zone_subnet_id" {
  description = "Private subnet ID in the One Zone AZ. Required when efs_one_zone_az is set."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# ECR
# -----------------------------------------------------------------------------

variable "ecr_force_delete" {
  description = "Whether to allow force deletion of the ECR repository (including images)."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Auth
# -----------------------------------------------------------------------------

variable "shibboleth2_xml" {
  description = "Content of shibboleth2.xml configuration file."
  type        = string
  default     = "placeholder"
  sensitive   = true
}

variable "shibboleth_attribute_map_xml" {
  description = "Content of attribute-map.xml configuration file."
  type        = string
  default     = "placeholder"
  sensitive   = true
}

variable "shibboleth_sp_cert" {
  description = "Content of sp-cert.pem (Shibboleth SP certificate)."
  type        = string
  default     = "placeholder"
  sensitive   = true
}

variable "shibboleth_sp_key" {
  description = "Content of sp-key.pem (Shibboleth SP private key)."
  type        = string
  default     = "placeholder"
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

variable "enable_enhanced_monitoring" {
  description = "If true, creates the Vireo CloudWatch alarms and dashboard. Alarm actions are wired to sns_topic_arn when it is non-null; when null, alarms still create with empty action lists."
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "The ARN of the shared SNS topic for alarms."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "The number of days to retain CloudWatch logs."
  type        = number
  default     = 30
}

# -----------------------------------------------------------------------------
# ALB Logs
# -----------------------------------------------------------------------------

variable "alb_access_logs_enabled" {
  description = "Whether to enable ALB access logs to S3. Disabled by default."
  type        = bool
  default     = false
}

variable "alb_access_logs_retention_days" {
  description = "Number of days to retain ALB access logs in S3."
  type        = number
  default     = 90
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
  default     = {}
}
