variable "organization" {
  description = "The organization name (e.g., jhu)."
  type        = string
  default     = "jhu"
}

variable "project_name" {
  description = "A name for the project to be used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

# Infrastructure dependencies (passed from foundation module)
variable "vpc_id" {
  description = "The ID of the VPC to deploy resources in."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs to use for ECS tasks."
  type        = list(string)
}

variable "ecs_cluster_id" {
  description = "The ID of the ECS cluster (from foundation module)."
  type        = string
}

variable "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster (from foundation module)."
  type        = string
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster (from foundation module)."
  type        = string
}

variable "ecs_security_group_id" {
  description = "The ID of the ECS service security group."
  type        = string
}

variable "private_solr_listener_arn" {
  description = "The ARN of the private ALB Solr listener (port 8983)."
  type        = string
}

variable "private_alb_security_group_id" {
  description = "The ID of the private ALB security group."
  type        = string
}

variable "service_discovery_namespace_id" {
  description = "The ID of the CloudMap service discovery namespace."
  type        = string
}

variable "service_discovery_namespace_name" {
  description = "The name of the CloudMap service discovery namespace."
  type        = string
}

variable "private_alb_name" {
  description = "The name of the private ALB (for network interface discovery)."
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "The ARN of the ECS task execution role."
  type        = string
}

variable "ecs_task_role_arn" {
  description = "The ARN of the ECS task role."
  type        = string
}

# Solr-specific configuration
variable "zk_host_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret containing the Zookeeper host information."
  type        = string
  default     = null
}

variable "zookeeper_host_ssm_arn" {
  description = "ARN of SSM parameter containing Zookeeper host information (required when use_external_task_definitions = false)."
  type        = string
  default     = null

  validation {
    condition     = var.use_external_task_definitions || var.zookeeper_host_ssm_arn != null
    error_message = "zookeeper_host_ssm_arn is required when use_external_task_definitions = false"
  }
}

variable "db_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret containing the database credentials."
  type        = string
}

variable "db_credentials_ssm_arn" {
  description = "ARN of SSM parameter containing database credentials (required when use_external_task_definitions = false)."
  type        = string
  default     = null

  validation {
    condition     = var.use_external_task_definitions || var.db_credentials_ssm_arn != null
    error_message = "db_credentials_ssm_arn is required when use_external_task_definitions = false"
  }
}

variable "solr_efs_file_system_id" {
  description = "EFS file system ID for Solr data volumes (required when use_external_task_definitions = false)."
  type        = string
  default     = null

  validation {
    condition     = var.use_external_task_definitions || var.solr_efs_file_system_id != null
    error_message = "solr_efs_file_system_id is required when use_external_task_definitions = false"
  }
}

variable "zookeeper_efs_file_system_id" {
  description = "EFS file system ID for Zookeeper data volumes (required when use_external_task_definitions = false and deploy_zookeeper = true)."
  type        = string
  default     = null

  validation {
    condition     = var.use_external_task_definitions || !var.deploy_zookeeper || var.zookeeper_efs_file_system_id != null
    error_message = "zookeeper_efs_file_system_id is required when use_external_task_definitions = false and deploy_zookeeper = true"
  }
}

variable "desired_task_count" {
  description = "The desired number of tasks to run in the ECS service."
  type        = number
  default     = 1
}

variable "solr_node_count" {
  description = "The number of individual Solr nodes (services) to deploy with DNS-based identities."
  type        = number
  default     = 3
}

variable "max_task_count" {
  description = "The maximum number of tasks for auto scaling."
  type        = number
  default     = 4
}

variable "zookeeper_task_count" {
  description = "The number of Zookeeper tasks to run. Should be odd number (3 or 5) for proper quorum."
  type        = number
  default     = 3
}

variable "alarms_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
  default     = ""
}

variable "ecr_repositories" {
  description = "A list of ECR repository names to create."
  type        = list(string)
  default     = ["solr"]
}

variable "solr_image_name" {
  description = "The name of the Solr Docker image to use."
  type        = string
  default     = "solr"
}

variable "solr_image_tag" {
  description = "The tag of the Solr Docker image to use."
  type        = string
  default     = "latest"
}

variable "solr_image" {
  description = "Docker image URI for Solr (required when use_external_task_definitions = false)."
  type        = string
  default     = null

  validation {
    condition     = var.use_external_task_definitions || var.solr_image != null
    error_message = "solr_image is required when use_external_task_definitions = false"
  }
}

variable "solr_cpu" {
  description = "The CPU units for the Solr task."
  type        = number
  default     = 2048
}

variable "solr_memory" {
  description = "The memory (in MiB) for the Solr task."
  type        = number
  default     = 16384
}

variable "solr_opts" {
  description = "JVM tuning parameters for Solr (e.g., heap size settings)."
  type        = string
  default     = "-Xms8g -Xmx8g"
}

variable "deploy_zookeeper" {
  description = "Whether to deploy a Zookeeper service."
  type        = bool
  default     = false
}

variable "zookeeper_image" {
  description = "Docker image URI for Zookeeper (required when use_external_task_definitions = false and deploy_zookeeper = true)."
  type        = string
  default     = null

  validation {
    condition     = var.use_external_task_definitions || !var.deploy_zookeeper || var.zookeeper_image != null
    error_message = "zookeeper_image is required when use_external_task_definitions = false and deploy_zookeeper = true"
  }
}

variable "zookeeper_cpu" {
  description = "The CPU units for the Zookeeper task."
  type        = number
  default     = 512
}

variable "zookeeper_memory" {
  description = "The memory (in MiB) for the Zookeeper task."
  type        = number
  default     = 1024
}

variable "zookeeper_jvmflags" {
  description = "JVM tuning parameters for Zookeeper (e.g., heap size settings)."
  type        = string
  default     = ""
}

variable "solr_image_override" {
  description = "Override the default Solr image with a custom image URI."
  type        = string
  default     = null
}

variable "enable_enhanced_monitoring" {
  description = "Whether to enable enhanced monitoring features."
  type        = bool
  default     = false
}

variable "enable_event_capture" {
  description = "Whether to enable ECS event capture for enhanced monitoring."
  type        = bool
  default     = false
}

variable "alarm_notification_email" {
  description = "Email address to receive CloudWatch alarm notifications."
  type        = string
  default     = null
}

variable "sns_topic_arn" {
  description = "The ARN of the SNS topic for alarms (from DRCC foundation module)."
  type        = string
  default     = null
}

variable "public_domain" {
  description = "The public domain name for the DSpace application."
  type        = string
}

variable "db_endpoint" {
  description = "The database endpoint for the DSpace application."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
  default     = {}
}

# Resource Naming Variables

variable "cloudwatch_dashboard_name" {
  description = "The name of the CloudWatch dashboard."
  type        = string
  default     = null
}

variable "use_external_task_definitions" {
  description = "Whether to use externally managed task definitions instead of module-generated ones."
  type        = bool
  default     = false
}

variable "solr_task_def_arns" {
  description = "List of external task definition ARNs for Solr nodes (required when use_external_task_definitions = true)."
  type        = list(string)
  default     = []

  validation {
    condition     = !var.use_external_task_definitions || length(var.solr_task_def_arns) == var.solr_node_count
    error_message = "solr_task_def_arns must contain exactly solr_node_count ARNs when use_external_task_definitions = true."
  }
}

variable "zookeeper_task_def_arns" {
  description = "List of external task definition ARNs for Zookeeper nodes (required when use_external_task_definitions = true and deploy_zookeeper = true)."
  type        = list(string)
  default     = []

  validation {
    condition     = !var.use_external_task_definitions || !var.deploy_zookeeper || length(var.zookeeper_task_def_arns) == var.zookeeper_task_count
    error_message = "zookeeper_task_def_arns must contain exactly zookeeper_task_count ARNs when use_external_task_definitions = true and deploy_zookeeper = true."
  }
}

# Solr Auto-scaling Configuration
variable "enable_solr_autoscaling" {
  description = "Enable Solr auto-scaling policies and collection templates"
  type        = bool
  default     = true
}

variable "solr_cluster_policies" {
  description = "Solr cluster auto-scaling policies"
  type = list(object({
    replica    = optional(string)
    shard      = optional(string)
    collection = optional(string)
    cores      = optional(string)
    node       = optional(string)
    strict     = optional(bool)
  }))
  default = [
    {
      replica    = "1"
      shard      = "#EACH"
      collection = "#ANY"
      strict     = false
    },
    {
      cores = "<5"
      node  = "#ANY"
    }
  ]
}

variable "solr_collection_templates" {
  description = "Solr collection templates with auto-recovery settings"
  type = map(object({
    numShards         = optional(number)
    replicationFactor = optional(number)
    autoAddReplicas   = optional(bool)
    maxShardsPerNode  = optional(number)
  }))
  default = {
    dspace_default = {
      numShards         = 1
      replicationFactor = 3
      autoAddReplicas   = true
      maxShardsPerNode  = 2
    }
  }
}
