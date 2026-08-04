# Basic configuration
variable "organization" {
  description = "Organization identifier used in resource names and tags."
  type        = string
  default     = "jhu"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.organization))
    error_message = "organization must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "project_name" {
  description = "Project identifier used in resource names and tags."
  type        = string
  default     = "repository-mcp"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment: stage or prod. The prod value is normalized to production for the MCP application."
  type        = string

  validation {
    condition     = contains(["stage", "prod"], var.environment)
    error_message = "environment must be stage or prod."
  }
}

variable "resource_name_prefix" {
  description = "Optional resource-name override. Use the legacy prefix during state migration to avoid name churn."
  type        = string
  default     = null

  validation {
    condition = var.resource_name_prefix == null || (
      length(var.resource_name_prefix) <= 24 &&
      can(regex("^[a-z0-9][a-z0-9-]*$", var.resource_name_prefix))
    )
    error_message = "resource_name_prefix must be at most 24 lowercase alphanumeric or hyphen characters."
  }
}

variable "tags" {
  description = "Additional tags to merge with the module's standard tags."
  type        = map(string)
  default     = {}
}

# Foundation dependencies
variable "vpc_id" {
  description = "VPC ID for the MCP service and target group."
  type        = string
}

variable "vpc_cidr_block" {
  description = "IPv4 VPC CIDR block used to restrict DNS egress from MCP tasks."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr_block))
    error_message = "vpc_cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where MCP Fargate tasks run."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "private_subnet_ids must contain at least two subnets for availability-zone redundancy."
  }
}

variable "ecs_cluster_id" {
  description = "Shared ECS cluster ID from the foundation module."
  type        = string
}

variable "ecs_cluster_name" {
  description = "Shared ECS cluster name used by autoscaling and CloudWatch dimensions."
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "Shared ECS task execution role ARN from the foundation module."
  type        = string
}

variable "ecs_task_role_arn" {
  description = "Shared ECS task role ARN from the foundation module."
  type        = string
}

variable "public_alb_https_listener_arn" {
  description = "HTTPS listener ARN for the foundation-managed public ALB."
  type        = string
}

variable "public_alb_security_group_id" {
  description = "Security group ID for the foundation-managed public ALB."
  type        = string
}

variable "public_alb_arn_suffix" {
  description = "ARN suffix for the foundation-managed public ALB, used in metrics and request-count autoscaling."
  type        = string
}

variable "public_alb_certificate_arn" {
  description = "Optional ACM certificate ARN to add to the shared HTTPS listener when its default certificate does not cover public_hostname."
  type        = string
  default     = null

  validation {
    condition     = var.public_alb_certificate_arn == null || can(regex("^arn:[^:]+:acm:[^:]+:[0-9]{12}:certificate/", var.public_alb_certificate_arn))
    error_message = "public_alb_certificate_arn must be a valid ACM certificate ARN or null."
  }
}

# Repository backend network dependencies
variable "jscholarship_solr_security_group_id" {
  description = "Security group ID for JScholarship Solr. The module adds reciprocal TCP access on jscholarship_solr_port."
  type        = string
}

variable "jscholarship_api_security_group_id" {
  description = "Security group ID for the JScholarship API endpoint, normally the DSpace private ALB security group."
  type        = string
}

variable "jhrdr_solr_security_group_id" {
  description = "Optional JHRDR Solr security group ID. Null disables reciprocal JHRDR Solr rules."
  type        = string
  default     = null
}

variable "jhrdr_api_security_group_id" {
  description = "Optional JHRDR API security group ID. Null disables reciprocal JHRDR API rules."
  type        = string
  default     = null
}

variable "jscholarship_solr_port" {
  description = "JScholarship Solr TCP port."
  type        = number
  default     = 8983

  validation {
    condition     = var.jscholarship_solr_port >= 1 && var.jscholarship_solr_port <= 65535
    error_message = "jscholarship_solr_port must be between 1 and 65535."
  }
}

variable "jscholarship_api_port" {
  description = "JScholarship API endpoint TCP port; use 80 for the foundation private ALB."
  type        = number
  default     = 80

  validation {
    condition     = var.jscholarship_api_port >= 1 && var.jscholarship_api_port <= 65535
    error_message = "jscholarship_api_port must be between 1 and 65535."
  }
}

variable "jhrdr_solr_port" {
  description = "JHRDR Solr TCP port."
  type        = number
  default     = 8983

  validation {
    condition     = var.jhrdr_solr_port >= 1 && var.jhrdr_solr_port <= 65535
    error_message = "jhrdr_solr_port must be between 1 and 65535."
  }
}

variable "jhrdr_api_port" {
  description = "JHRDR API TCP port."
  type        = number
  default     = 8080

  validation {
    condition     = var.jhrdr_api_port >= 1 && var.jhrdr_api_port <= 65535
    error_message = "jhrdr_api_port must be between 1 and 65535."
  }
}

# Task definition and container
variable "use_external_task_definitions" {
  description = "Whether an external pipeline supplies the MCP task definition instead of this module creating it."
  type        = bool
  default     = false
}

variable "mcp_task_def_arn" {
  description = "External MCP task definition ARN, required when use_external_task_definitions is true."
  type        = string
  default     = null
}

variable "mcp_image" {
  description = "MCP container image URI with an immutable tag or digest, required for Terraform-managed task definitions."
  type        = string
  default     = null
}

variable "container_name" {
  description = "Container name in the MCP task definition. External task definitions must use the same value."
  type        = string
  default     = "repository-mcp"
}

variable "container_port" {
  description = "Port exposed by the MCP container."
  type        = number
  default     = 3000

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 512

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.task_cpu)
    error_message = "task_cpu must be a supported Fargate CPU value."
  }
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

  validation {
    condition     = contains(["FARGATE", "FARGATE_SPOT"], var.capacity_provider)
    error_message = "capacity_provider must be FARGATE or FARGATE_SPOT."
  }
}

variable "log_group_name" {
  description = "Optional CloudWatch log group name override."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 90

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545,
      731, 1096, 1827, 2192, 2557, 2922, 3288, 3653,
    ], var.log_retention_days)
    error_message = "log_retention_days must be a retention period supported by CloudWatch Logs."
  }
}

variable "log_level" {
  description = "Optional MCP log level. Defaults to info in prod and debug elsewhere."
  type        = string
  default     = null

  validation {
    condition     = var.log_level == null || contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "log_level must be debug, info, warn, error, or null."
  }
}

# Application endpoints
variable "public_hostname" {
  description = "Public hostname routed to this MCP service."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$", lower(var.public_hostname)))
    error_message = "public_hostname must be a valid DNS hostname."
  }
}

variable "listener_rule_priority" {
  description = "Unique priority for the MCP host-based HTTPS listener rule."
  type        = number

  validation {
    condition     = var.listener_rule_priority >= 1 && var.listener_rule_priority <= 49999
    error_message = "listener_rule_priority must be between 1 and 49999; priority 50000 is reserved for the DSpace UI catch-all rule."
  }
}

variable "jscholarship_solr_url" {
  description = "Internal JScholarship Solr search collection URL."
  type        = string
}

variable "jscholarship_api_url" {
  description = "Internal JScholarship REST API URL."
  type        = string
}

variable "jscholarship_public_url" {
  description = "Public JScholarship base URL used for record links."
  type        = string
}

variable "jhrdr_solr_url" {
  description = "Internal JHRDR Solr URL. Empty disables the adapter endpoint."
  type        = string
  default     = ""
}

variable "jhrdr_api_url" {
  description = "Internal JHRDR API URL. Empty disables the adapter endpoint."
  type        = string
  default     = ""
}

variable "jhrdr_public_url" {
  description = "Public JHRDR base URL. Empty disables record links for the adapter."
  type        = string
  default     = ""
}

# Service scaling and observability
variable "service_desired_count" {
  description = "Initial desired MCP task count."
  type        = number
  default     = 1

  validation {
    condition     = var.service_desired_count >= 0
    error_message = "service_desired_count cannot be negative."
  }
}

variable "service_min_count" {
  description = "Minimum MCP task count for autoscaling."
  type        = number
  default     = 1

  validation {
    condition     = var.service_min_count >= 0
    error_message = "service_min_count cannot be negative."
  }
}

variable "service_max_count" {
  description = "Maximum MCP task count for autoscaling."
  type        = number
  default     = 6

  validation {
    condition     = var.service_max_count >= 1
    error_message = "service_max_count must be at least one."
  }
}

variable "autoscaling_cpu_target" {
  description = "Target average ECS CPU utilization percentage."
  type        = number
  default     = 70

  validation {
    condition     = var.autoscaling_cpu_target > 0 && var.autoscaling_cpu_target <= 100
    error_message = "autoscaling_cpu_target must be greater than zero and at most 100."
  }
}

variable "autoscaling_requests_per_target" {
  description = "Target ALB requests per task used by target tracking."
  type        = number
  default     = 100

  validation {
    condition     = var.autoscaling_requests_per_target > 0
    error_message = "autoscaling_requests_per_target must be greater than zero."
  }
}

variable "alarm_sns_topic_arn" {
  description = "Optional SNS topic ARN for MCP CloudWatch alarms. Null disables alarm creation."
  type        = string
  default     = null
}
