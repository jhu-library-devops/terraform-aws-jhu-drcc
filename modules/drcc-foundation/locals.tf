# Data sources and local values
locals {
  name = "${var.project_name}-${var.environment}"
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "OpenTofu" # Compatible with Terraform
  }

  # Network resource selection
  vpc_id             = var.create_vpc ? aws_vpc.main[0].id : var.vpc_id
  vpc_cidr           = var.create_vpc ? var.vpc_cidr : data.aws_vpc.existing[0].cidr_block
  public_subnet_ids  = var.create_vpc ? aws_subnet.public[*].id : var.public_subnet_ids
  private_subnet_ids = var.create_vpc ? aws_subnet.private[*].id : var.private_subnet_ids

  # Database configuration
  db_secret_arn_final = var.deploy_database ? aws_secretsmanager_secret.db[0].arn : var.db_credentials_secret_arn_override

  # ALB logging configuration
  alb_log_prefix = "dspace-alb"
}

data "aws_vpc" "existing" {
  count = !var.create_vpc ? 1 : 0
  id    = var.vpc_id
}

data "aws_db_instance" "existing" {
  count                  = !var.deploy_database && var.db_instance_identifier != null ? 1 : 0
  db_instance_identifier = var.db_instance_identifier
}

data "aws_elb_service_account" "main" {}
