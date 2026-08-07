# =============================================================================
# VIREO COMPLETE EXAMPLE - VARIABLES
# =============================================================================

# -----------------------------------------------------------------------------
# Identity
# -----------------------------------------------------------------------------

variable "organization" {
  description = "The organization identifier used in resource naming."
  type        = string
}

variable "project_name" {
  description = "The project name used in resource naming and SSM parameter paths."
  type        = string
  default     = "vireo"
}

variable "environment" {
  description = "The deployment environment (e.g. stage, prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
}

# -----------------------------------------------------------------------------
# Domain
# -----------------------------------------------------------------------------

variable "public_domain" {
  description = "The public domain name for Vireo (e.g. etd.example.edu)."
  type        = string
}

variable "ses_email_domain" {
  description = "The domain to register as an SES identity for sending email."
  type        = string
}

variable "internal_hosted_zone_name" {
  description = "The name of the Route53 private hosted zone for the internal ALB."
  type        = string
}

# -----------------------------------------------------------------------------
# ECS Tasks
# -----------------------------------------------------------------------------

variable "proxy_task_family" {
  description = "The ECS task definition family name for the proxy service."
  type        = string
}

variable "proxy_container_name" {
  description = "The container name in the proxy task definition."
  type        = string
}

variable "app_task_family" {
  description = "The ECS task definition family name for the Vireo app service."
  type        = string
}

variable "app_container_name" {
  description = "The container name in the Vireo app task definition."
  type        = string
}

# -----------------------------------------------------------------------------
# Storage
# -----------------------------------------------------------------------------

variable "vireo_s3_bucket_name" {
  description = "The name of the S3 bucket for Vireo ETL jobs."
  type        = string
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "A map of tags to assign to all resources."
  type        = map(string)
  default     = {}
}
