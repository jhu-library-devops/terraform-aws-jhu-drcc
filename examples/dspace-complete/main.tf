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

# DRCC Foundation - Core infrastructure
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

  # Database Configuration
  deploy_database      = true
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name              = var.db_name
  db_username          = var.db_username
  db_multi_az          = var.db_multi_az
}

# Solr Search Cluster
module "solr" {
  source = "../../modules/solr-search-cluster"

  organization = var.organization
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # Infrastructure dependencies from foundation
  vpc_id                           = module.foundation.vpc_id
  private_subnet_ids               = module.foundation.private_subnet_ids
  ecs_cluster_id                   = module.foundation.ecs_cluster_id
  ecs_cluster_arn                  = module.foundation.ecs_cluster_arn
  ecs_cluster_name                 = module.foundation.ecs_cluster_name
  ecs_security_group_id            = module.foundation.ecs_security_group_id
  private_solr_listener_arn        = module.foundation.private_solr_listener_arn
  private_alb_security_group_id    = module.foundation.private_alb_security_group_id
  private_alb_name                 = module.foundation.private_alb_name
  service_discovery_namespace_id   = module.foundation.service_discovery_namespace_id
  service_discovery_namespace_name = module.foundation.service_discovery_namespace_name
  ecs_task_execution_role_arn      = module.foundation.ecs_task_execution_role_arn
  ecs_task_role_arn                = module.foundation.ecs_task_role_arn
  db_secret_arn                    = module.foundation.db_credentials_secret_arn

  # Solr configuration
  solr_node_count      = var.solr_node_count
  deploy_zookeeper     = var.deploy_zookeeper
  zookeeper_task_count = var.zookeeper_task_count
  solr_cpu             = var.solr_cpu
  solr_memory          = var.solr_memory

  # Required attributes
  db_endpoint   = module.foundation.db_instance_endpoint
  public_domain = var.public_domain
}

# DSpace Application Services
module "dspace_app" {
  source = "../../modules/dspace-app-services"

  organization = var.organization
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # Infrastructure dependencies from foundation
  vpc_id                      = module.foundation.vpc_id
  private_subnet_ids          = module.foundation.private_subnet_ids
  ecs_cluster_id              = module.foundation.ecs_cluster_id
  ecs_cluster_arn             = module.foundation.ecs_cluster_arn
  ecs_security_group_id       = module.foundation.ecs_security_group_id
  ecs_task_execution_role_arn = module.foundation.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.foundation.ecs_task_role_arn
  alb_https_listener_arn      = module.foundation.alb_https_listener_arn
  private_alb_listener_arn    = module.foundation.private_alb_listener_arn

  # Initialization configuration
  enable_init_tasks = var.enable_init_tasks
  db_secret_arn     = module.foundation.db_credentials_secret_arn
  solr_url          = "http://${module.foundation.private_alb_dns_name}:8983/solr"
  dspace_api_image  = var.dspace_api_image

  # Task definitions (if using external definitions)
  dspace_angular_task_def_arn = var.dspace_angular_task_def_arn
  dspace_api_task_def_arn     = var.dspace_api_task_def_arn
  dspace_jobs_task_def_arn    = var.dspace_jobs_task_def_arn

  # Task counts
  dspace_angular_task_count = var.dspace_angular_task_count
  dspace_api_task_count     = var.dspace_api_task_count

  # Required attributes
  dspace_asset_store_bucket_name = var.dspace_asset_store_bucket_name
  alarm_notification_email       = var.alarm_notification_email
}
