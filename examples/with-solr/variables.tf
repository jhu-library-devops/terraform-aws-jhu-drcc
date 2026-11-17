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
  description = "Public domain name used by the HTTPS load balancer."
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
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN for externally managed database credentials."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:secretsmanager:[^:]+:[0-9]{12}:secret:", var.db_secret_arn))
    error_message = "db_secret_arn must be a valid Secrets Manager ARN."
  }
}

variable "db_endpoint" {
  description = "Reachable external PostgreSQL endpoint consumed by Solr tasks."
  type        = string
}

variable "solr_node_count" {
  description = "Number of Solr nodes."
  type        = number
  default     = 3
}

variable "deploy_zookeeper" {
  description = "Whether to deploy the Zookeeper ensemble."
  type        = bool
  default     = true
}

variable "zookeeper_task_count" {
  description = "Number of Zookeeper nodes."
  type        = number
  default     = 3
}

variable "solr_cpu" {
  description = "CPU units per Solr task."
  type        = number
  default     = 1024
}

variable "solr_memory" {
  description = "Memory in MiB per Solr task."
  type        = number
  default     = 2048
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
