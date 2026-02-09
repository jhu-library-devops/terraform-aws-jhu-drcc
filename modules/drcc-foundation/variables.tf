variable "organization" {
  description = "The organization name (e.g., jhu)."
  type        = string
  default     = "jhu"
}

variable "project_name" {
  description = "A name for the project to be used in resource names and tags."
  type        = string
}

variable "public_domain" {
  description = "The public domain name of the dspace application."
  type        = string
  default     = null
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "create_vpc" {
  description = "Controls if a new VPC and networking resources should be created."
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC. Used only when create_vpc is true."
  type        = string
  default     = null
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets. Used only when create_vpc is true."
  type        = list(string)
  default     = null
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets. Used only when create_vpc is true."
  type        = list(string)
  default     = null
}

variable "vpc_id" {
  description = "The ID of an existing VPC to use. Required if create_vpc is false."
  type        = string
  default     = null
}

variable "public_subnet_ids" {
  description = "A list of existing public subnet IDs to use for the ALB. Required if create_vpc is false."
  type        = list(string)
  default     = null
}

variable "private_subnet_ids" {
  description = "A list of existing private subnet IDs to use for ECS tasks. Required if create_vpc is false."
  type        = list(string)
  default     = null
}

variable "deploy_database" {
  description = "If true, deploys a new RDS PostgreSQL database. If false, the module can use an existing database by providing `db_instance_identifier` and `db_credentials_secret_arn_override`."
  type        = bool
  default     = false
}

variable "db_instance_class" {
  description = "The instance class for the RDS database."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "The allocated storage in gigabytes for the RDS database."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "The name of the database to create in the RDS instance."
  type        = string
  default     = "dspace"
}

variable "db_username" {
  description = "The master username for the RDS database."
  type        = string
  default     = "dspaceuser"
}

variable "db_multi_az" {
  description = "Specifies if the RDS instance is multi-AZ. Should be true for production."
  type        = bool
  default     = false
}

variable "db_engine_version" {
  description = "The engine version of the RDS instance."
  type        = string
  default     = "17.4"
}

variable "db_backup_retention_period" {
  description = "The days to retain backups for. Must be > 0 to enable backups. Recommended: 7+ for production."
  type        = number
  default     = 7
}

variable "db_deletion_protection" {
  description = "If the DB instance should have deletion protection enabled. Should be true for production."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted. Should be false for production."
  type        = bool
  default     = true
}

variable "db_instance_identifier" {
  description = "The identifier of an existing RDS instance to use. Required if `deploy_database` is false."
  type        = string
  default     = null
}

variable "db_credentials_secret_arn_override" {
  description = "The ARN of an existing Secrets Manager secret containing database credentials."
  type        = string
  default     = null
}

variable "enable_enhanced_monitoring" {
  description = "Whether to enable enhanced monitoring features."
  type        = bool
  default     = false
}

variable "alarm_notification_email" {
  description = "Email address to receive CloudWatch alarm notifications."
  type        = string
  default     = null
}

variable "alb_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssl_certificate_arn" {
  description = "The ARN of the SSL certificate to use for HTTPS listeners."
  type        = string
  default     = null
}

variable "trusted_ip_set_arn" {
  description = "The ARN of the WAF Trusted IP Set."
  type        = string
  default     = null
}

variable "waf_verified_bots_action" {
  description = "The action to take for verified bots."
  type        = string
  default     = "allow"
}

variable "deploy_dspace_config_efs" {
  description = "Whether to deploy EFS for DSpace configuration storage."
  type        = bool
  default     = false
}

variable "app_email_domain" {
  description = "The application email domain for SES configuration."
  type        = string
  default     = "jscholarship.library.jhu.edu"
}

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
  default     = {}
}

variable "alb_idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle."
  type        = number
  default     = 60
}

variable "health_check_interval" {
  description = "The approximate amount of time between health checks of an individual target."
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "The amount of time to wait when receiving a response from the health check."
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "The number of consecutive health checks successes required before considering an unhealthy target healthy."
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "The number of consecutive health check failures required before considering a target unhealthy."
  type        = number
  default     = 3
}

# Resource Naming Variables
variable "vpc_name" {
  description = "The name of the VPC."
  type        = string
  default     = null
}

variable "alb_name" {
  description = "The name of the Application Load Balancer."
  type        = string
  default     = null
}

variable "sns_topic_name" {
  description = "The name of the SNS topic for alerts."
  type        = string
  default     = null
}

variable "db_secret_rotation_type" {
  description = "The type of database secret rotation (manual or automatic)."
  type        = string
  default     = "manual"
}
