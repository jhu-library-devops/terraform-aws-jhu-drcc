terraform {
  required_version = ">= 1.0"
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

# DRCC Foundation - Core infrastructure (VPC + ECS Cluster)
module "foundation" {
  source = "../../modules/drcc-foundation"

  organization = var.organization
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # VPC Configuration
  create_vpc           = true
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# Vireo Application Services
module "vireo_app_services" {
  source = "../../modules/vireo-app-services"

  # Identity
  organization = var.organization
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # Infrastructure from foundation
  vpc_id             = module.foundation.vpc_id
  private_subnet_ids = module.foundation.private_subnet_ids
  public_subnet_ids  = module.foundation.public_subnet_ids
  ecs_cluster_id     = module.foundation.ecs_cluster_id

  # Domain
  public_domain             = var.public_domain
  ses_email_domain          = var.ses_email_domain
  internal_hosted_zone_name = var.internal_hosted_zone_name

  # ECS Tasks
  proxy_task_family    = var.proxy_task_family
  proxy_container_name = var.proxy_container_name
  app_task_family      = var.app_task_family
  app_container_name   = var.app_container_name

  # Storage
  vireo_s3_bucket_name = var.vireo_s3_bucket_name

  # Tags
  tags = var.tags
}
