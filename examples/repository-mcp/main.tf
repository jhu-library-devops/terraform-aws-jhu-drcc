terraform {
  required_version = ">= 1.10"

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

module "repository_mcp" {
  source = "../../modules/repository-mcp-service"

  organization         = var.organization
  project_name         = var.project_name
  environment          = var.environment
  resource_name_prefix = var.resource_name_prefix
  tags                 = var.tags

  vpc_id             = var.vpc_id
  vpc_cidr_block     = var.vpc_cidr_block
  private_subnet_ids = var.private_subnet_ids

  ecs_cluster_id              = var.ecs_cluster_id
  ecs_cluster_name            = var.ecs_cluster_name
  ecs_task_execution_role_arn = var.ecs_task_execution_role_arn
  ecs_task_role_arn           = var.ecs_task_role_arn

  public_alb_https_listener_arn = var.public_alb_https_listener_arn
  public_alb_security_group_id  = var.public_alb_security_group_id
  public_alb_arn_suffix         = var.public_alb_arn_suffix
  public_alb_certificate_arn    = var.public_alb_certificate_arn

  jscholarship_solr_security_group_id = var.jscholarship_solr_security_group_id
  jscholarship_api_security_group_id  = var.jscholarship_api_security_group_id
  jhrdr_solr_security_group_id        = var.jhrdr_solr_security_group_id
  jhrdr_api_security_group_id         = var.jhrdr_api_security_group_id

  use_external_task_definitions = var.use_external_task_definitions
  mcp_task_def_arn              = var.mcp_task_def_arn
  mcp_image                     = var.mcp_image
  task_cpu                      = var.task_cpu
  task_memory                   = var.task_memory
  capacity_provider             = var.capacity_provider

  public_hostname        = var.public_hostname
  listener_rule_priority = var.listener_rule_priority

  jscholarship_solr_url   = var.jscholarship_solr_url
  jscholarship_api_url    = var.jscholarship_api_url
  jscholarship_public_url = var.jscholarship_public_url
  jhrdr_solr_url          = var.jhrdr_solr_url
  jhrdr_api_url           = var.jhrdr_api_url
  jhrdr_public_url        = var.jhrdr_public_url

  service_desired_count = var.service_desired_count
  service_min_count     = var.service_min_count
  service_max_count     = var.service_max_count
  log_retention_days    = var.log_retention_days
  alarm_sns_topic_arn   = var.alarm_sns_topic_arn
}
