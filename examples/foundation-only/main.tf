terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# DRCC Foundation - Core infrastructure only
module "foundation" {
  source = "../../modules/drcc-foundation"

  organization  = var.organization
  project_name  = var.project_name
  environment   = var.environment
  aws_region    = var.aws_region
  public_domain = var.public_domain

  # VPC Configuration
  create_vpc           = true
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  create_ssl_certificate = var.create_ssl_certificate
  ssl_certificate_arn    = var.ssl_certificate_arn
}

# Outputs for use by other modules
output "vpc_id" {
  value = module.foundation.vpc_id
}

output "private_subnet_ids" {
  value = module.foundation.private_subnet_ids
}

output "ecs_security_group_id" {
  value = module.foundation.ecs_security_group_id
}

output "alb_dns_name" {
  value = module.foundation.alb_dns_name
}
