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

module "foundation" {
  source = "../../modules/drcc-foundation"

  organization  = var.organization
  project_name  = var.project_name
  environment   = var.environment
  aws_region    = var.aws_region
  public_domain = var.public_domain

  create_vpc           = true
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  create_ssl_certificate = var.create_ssl_certificate
  ssl_certificate_arn    = var.ssl_certificate_arn

  ecs_task_execution_secret_arns = [var.db_secret_arn]
  ecs_vpc_tcp_egress_ports       = [5432]
}

module "solr" {
  source = "../../modules/solr-search-cluster"

  organization = var.organization
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

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

  db_secret_arn = var.db_secret_arn
  db_endpoint   = var.db_endpoint
  public_domain = var.public_domain

  solr_node_count      = var.solr_node_count
  deploy_zookeeper     = var.deploy_zookeeper
  zookeeper_task_count = var.zookeeper_task_count
  solr_cpu             = var.solr_cpu
  solr_memory          = var.solr_memory
  solr_image_override  = var.solr_image
  zookeeper_image      = var.zookeeper_image
}

output "alb_dns_name" {
  description = "Public ALB DNS name."
  value       = module.foundation.alb_dns_name
}

output "private_alb_dns_name" {
  description = "Private ALB DNS name for Solr access."
  value       = module.foundation.private_alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.foundation.ecs_cluster_name
}

output "solr_service_discovery_namespace" {
  description = "Cloud Map namespace for Solr service discovery."
  value       = module.foundation.service_discovery_namespace_name
}
