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
  description = "Deprecated. Database creation is owned by dspace-app-services; this value must remain false."
  type        = bool
  default     = false

  validation {
    condition     = !var.deploy_database
    error_message = "deploy_database is no longer supported by drcc-foundation. Set it to false and configure database creation in dspace-app-services."
  }
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
  default     = "dspace"
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
  description = "The ARN of an existing database credentials secret. Database creation is owned by dspace-app-services."
  type        = string
  default     = null
}

variable "ecs_task_execution_secret_arns" {
  description = "Additional Secrets Manager ARNs that the shared ECS task execution role may read. Use for externally named database or application secrets."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.ecs_task_execution_secret_arns : can(regex("^arn:[^:]+:secretsmanager:[^:]+:[0-9]{12}:secret:", arn))])
    error_message = "ecs_task_execution_secret_arns must contain valid Secrets Manager ARNs."
  }
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

variable "ecs_vpc_tcp_egress_ports" {
  description = "TCP ports that shared DSpace ECS tasks may reach anywhere in the VPC CIDR. Keep empty for managed RDS; dspace-app-services creates an SG-specific database rule. Add 5432 only for a documented external PostgreSQL endpoint that cannot be referenced by security group."
  type        = list(number)
  default     = []

  validation {
    condition     = alltrue([for port in var.ecs_vpc_tcp_egress_ports : port >= 1 && port <= 65535])
    error_message = "ecs_vpc_tcp_egress_ports must contain valid TCP ports between 1 and 65535."
  }
}

variable "ecs_any_ipv4_tcp_egress_ports" {
  description = "TCP ports that shared DSpace ECS tasks may reach at any IPv4 destination, including routed private networks. Defaults support HTTPS APIs, image pulls, ECS Exec, and standard SMTP submission; add ports only for documented application dependencies."
  type        = list(number)
  default     = [25, 443, 465, 587]

  validation {
    condition     = alltrue([for port in var.ecs_any_ipv4_tcp_egress_ports : port >= 1 && port <= 65535])
    error_message = "ecs_any_ipv4_tcp_egress_ports must contain valid TCP ports between 1 and 65535."
  }
}

variable "create_ssl_certificate" {
  description = "Whether to create an ACM certificate for the public domain. When true, `public_domain` must be set. The certificate will require DNS validation."
  type        = bool
  default     = false
}

variable "ssl_certificate_arn" {
  description = "The ARN of an existing SSL certificate to use for HTTPS listeners. Ignored when `create_ssl_certificate` is true."
  type        = string
  default     = null
}

variable "create_trusted_ip_set" {
  description = "Whether to create a WAFv2 IP set for trusted IPs. When true, provide CIDRs via `trusted_ip_addresses`. When false, provide an existing IP set ARN via `trusted_ip_set_arn`."
  type        = bool
  default     = false
}

variable "trusted_ip_addresses" {
  description = "List of CIDR blocks for the trusted IP set. Used only when `create_trusted_ip_set` is true."
  type        = list(string)
  default     = []
}

variable "trusted_ip_set_arn" {
  description = "The ARN of an existing WAF Trusted IP Set. Ignored when `create_trusted_ip_set` is true."
  type        = string
  default     = null
}

variable "waf_verified_bots_action" {
  description = "The action to take for verified bots."
  type        = string
  default     = "allow"
}

variable "waf_block_non_browser_user_agents" {
  description = "Whether WAF blocks non-browser user agents that do not exactly match waf_approved_non_browser_user_agent. Disable only when machine clients such as MCP are protected by other WAF and application controls."
  type        = bool
  default     = true
}

variable "waf_approved_non_browser_user_agent" {
  description = "Exact non-browser User-Agent value allowed when waf_block_non_browser_user_agents is true."
  type        = string
  default     = "some-approved-user-agent"
}

variable "waf_rate_limit_per_ip" {
  description = "Maximum requests per five-minute window per source IP before the foundation WAF blocks requests."
  type        = number
  default     = 2000

  validation {
    condition     = var.waf_rate_limit_per_ip >= 100
    error_message = "waf_rate_limit_per_ip must be at least 100."
  }
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

variable "solr_cloudmap_service_id" {
  description = "The ID of the Cloud Map service for Solr ALB sync. Provided by the solr-search-cluster module."
  type        = string
  default     = ""
}

variable "public_hosted_zone_id" {
  description = "The ID of a public Route53 hosted zone. When set, an A record aliased to the public ALB is created for `public_domain`."
  type        = string
  default     = null
}
