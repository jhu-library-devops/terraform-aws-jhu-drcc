variable "organization" {
  description = "Organization name used in resource naming."
  type        = string
  default     = "jhu"
}

variable "project_name" {
  description = "Project name used in resource naming."
  type        = string
  default     = "dspace"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "public_domain" {
  description = "Public domain name for DSpace."
  type        = string
}

variable "create_ssl_certificate" {
  description = "Whether foundation creates an ACM certificate for public_domain. Certificate creation requires a staged DNS-validation workflow."
  type        = bool
  default     = false
}

variable "ssl_certificate_arn" {
  description = "Existing ACM certificate ARN when create_ssl_certificate is false."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks."
  type        = list(string)
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GiB."
  type        = number
}

variable "db_name" {
  description = "Database name."
  type        = string
  default     = "dspace"
}

variable "db_username" {
  description = "Database master username."
  type        = string
  default     = "dspace"
}

variable "db_multi_az" {
  description = "Whether the RDS instance is Multi-AZ."
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Number of days to retain RDS backups."
  type        = number
  default     = 7
}

variable "db_deletion_protection" {
  description = "Whether RDS deletion protection is enabled."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Whether to skip the final RDS snapshot on deletion."
  type        = bool
  default     = true
}

variable "solr_node_count" {
  description = "Number of Solr nodes."
  type        = number
}

variable "deploy_zookeeper" {
  description = "Whether to deploy the Zookeeper ensemble."
  type        = bool
}

variable "zookeeper_task_count" {
  description = "Number of Zookeeper nodes."
  type        = number
}

variable "solr_cpu" {
  description = "CPU units per Solr task."
  type        = number
  default     = 2048
}

variable "solr_memory" {
  description = "Memory in MiB per Solr task."
  type        = number
  default     = 16384
}

variable "solr_image" {
  description = "Optional complete Solr container image URI."
  type        = string
  default     = null
}

variable "zookeeper_image" {
  description = "Optional complete Zookeeper container image URI."
  type        = string
  default     = null
}

variable "use_external_task_definitions" {
  description = "Whether DSpace services use externally managed ECS task definitions."
  type        = bool
  default     = false
}

variable "dspace_angular_task_def_arn" {
  description = "External DSpace Angular task definition ARN."
  type        = string
  default     = null
}

variable "dspace_api_task_def_arn" {
  description = "External DSpace API task definition ARN."
  type        = string
  default     = null
}

variable "dspace_jobs_task_def_arn" {
  description = "External DSpace Jobs task definition ARN."
  type        = string
  default     = null
}

variable "dspace_angular_image" {
  description = "DSpace Angular image used for module-managed task definitions."
  type        = string
  default     = null
}

variable "dspace_api_image" {
  description = "DSpace API image used for module-managed task definitions and initialization."
  type        = string
  default     = null
}

variable "dspace_jobs_image" {
  description = "DSpace Jobs image used for module-managed task definitions."
  type        = string
  default     = null
}

variable "dspace_angular_cpu" {
  description = "CPU units for the DSpace Angular task."
  type        = number
  default     = 2048
}

variable "dspace_angular_memory" {
  description = "Memory in MiB for the DSpace Angular task."
  type        = number
  default     = 4096
}

variable "dspace_api_cpu" {
  description = "CPU units for the DSpace API task."
  type        = number
  default     = 2048
}

variable "dspace_api_memory" {
  description = "Memory in MiB for the DSpace API task."
  type        = number
  default     = 4096
}

variable "dspace_jobs_cpu" {
  description = "CPU units for the DSpace Jobs task."
  type        = number
  default     = 4096
}

variable "dspace_jobs_memory" {
  description = "Memory in MiB for the DSpace Jobs task."
  type        = number
  default     = 8192
}

variable "dspace_angular_task_count" {
  description = "Number of DSpace Angular tasks."
  type        = number
  default     = 1
}

variable "dspace_api_task_count" {
  description = "Number of DSpace API tasks."
  type        = number
  default     = 1
}

variable "enable_init_tasks" {
  description = "Whether to create the initialization Lambda and task definitions."
  type        = bool
  default     = false
}

variable "dspace_admin_email" {
  description = "Email address for the initial DSpace administrator."
  type        = string
  default     = "admin@example.edu"
}

variable "dspace_admin_first_name" {
  description = "First name for the initial DSpace administrator."
  type        = string
  default     = "Admin"
}

variable "dspace_admin_last_name" {
  description = "Last name for the initial DSpace administrator."
  type        = string
  default     = "User"
}

variable "dspace_admin_password_secret_arn" {
  description = "Secrets Manager ARN containing the initial administrator password as a plaintext secret value."
  type        = string
  default     = null

  validation {
    condition     = var.dspace_admin_password_secret_arn == null || can(regex("^arn:[^:]+:secretsmanager:[^:]+:[0-9]{12}:secret:", var.dspace_admin_password_secret_arn))
    error_message = "dspace_admin_password_secret_arn must be null or a valid Secrets Manager ARN."
  }
}

variable "dspace_asset_store_bucket_name" {
  description = "Globally unique S3 bucket name for DSpace assets."
  type        = string
}

variable "alarm_notification_email" {
  description = "Email address for CloudWatch alarm notifications."
  type        = string
}

variable "dspace_server_url_ssm_arn" {
  description = "SSM parameter ARN containing the DSpace server URL."
  type        = string
  default     = null
}

variable "dspace_server_ssr_url_ssm_arn" {
  description = "SSM parameter ARN containing the DSpace SSR server URL."
  type        = string
  default     = null
}

variable "dspace_ui_url_ssm_arn" {
  description = "SSM parameter ARN containing the DSpace UI URL."
  type        = string
  default     = null
}

variable "dspace_db_url_ssm_arn" {
  description = "SSM parameter ARN containing the DSpace database URL."
  type        = string
  default     = null
}

variable "dspace_db_username_ssm_arn" {
  description = "SSM parameter ARN containing the DSpace database username."
  type        = string
  default     = null
}

variable "dspace_db_password_ssm_arn" {
  description = "SSM parameter ARN containing the DSpace database password."
  type        = string
  default     = null
}

variable "dspace_solr_url_ssm_arn" {
  description = "SSM parameter ARN containing the DSpace Solr URL."
  type        = string
  default     = null
}

variable "dspace_mail_server_ssm_arn" {
  description = "SSM parameter ARN containing the mail server."
  type        = string
  default     = null
}

variable "dspace_mail_port_ssm_arn" {
  description = "SSM parameter ARN containing the mail port."
  type        = string
  default     = null
}

variable "dspace_mail_username_ssm_arn" {
  description = "SSM parameter ARN containing the mail username."
  type        = string
  default     = null
}

variable "dspace_mail_password_ssm_arn" {
  description = "SSM parameter ARN containing the mail password."
  type        = string
  default     = null
}

variable "dspace_mail_disabled_ssm_arn" {
  description = "SSM parameter ARN containing the mail-disabled flag."
  type        = string
  default     = null
}

variable "dspace_api_java_opts_ssm_arn" {
  description = "SSM parameter ARN containing DSpace API JVM options."
  type        = string
  default     = null
}

variable "dspace_jobs_java_opts_ssm_arn" {
  description = "SSM parameter ARN containing DSpace Jobs JVM options."
  type        = string
  default     = null
}

variable "dspace_google_analytics_key_ssm_arn" {
  description = "SSM parameter ARN containing the Google Analytics key."
  type        = string
  default     = null
}

variable "dspace_google_analytics_cron_ssm_arn" {
  description = "SSM parameter ARN containing the Google Analytics cron expression."
  type        = string
  default     = null
}

variable "dspace_google_analytics_api_secret_ssm_arn" {
  description = "SSM parameter ARN containing the Google Analytics API secret."
  type        = string
  default     = null
}

variable "dspace_rest_host_ssm_arn" {
  description = "SSM parameter ARN containing the DSpace REST host."
  type        = string
  default     = null
}

variable "dspace_rest_ssr_url_ssm_arn" {
  description = "SSM parameter ARN containing the DSpace REST SSR URL."
  type        = string
  default     = null
}

variable "dspace_angular_node_opts_ssm_arn" {
  description = "SSM parameter ARN containing DSpace Angular Node options."
  type        = string
  default     = null
}

variable "dspace_api_log_group_name" {
  description = "CloudWatch log group name for the DSpace API."
  type        = string
  default     = null
}

variable "dspace_angular_log_group_name" {
  description = "CloudWatch log group name for DSpace Angular."
  type        = string
  default     = null
}

variable "dspace_jobs_log_group_name" {
  description = "CloudWatch log group name for DSpace Jobs."
  type        = string
  default     = null
}
