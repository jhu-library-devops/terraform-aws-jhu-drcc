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
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 50
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

variable "solr_node_count" {
  description = "Number of Solr nodes"
  type        = number
  default     = 3
}

variable "deploy_zookeeper" {
  description = "Deploy Zookeeper cluster"
  type        = bool
  default     = true
}

variable "zookeeper_task_count" {
  description = "Number of Zookeeper nodes"
  type        = number
  default     = 3
}

variable "solr_cpu" {
  description = "Solr task CPU units"
  type        = string
  default     = "1024"
}

variable "solr_memory" {
  description = "Solr task memory in MB"
  type        = string
  default     = "2048"
}
