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

  ecs_task_execution_secret_arns = compact([var.dspace_admin_password_secret_arn])
}

module "dspace_app" {
  source = "../../modules/dspace-app-services"

  organization = var.organization
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_id                      = module.foundation.vpc_id
  private_subnet_ids          = module.foundation.private_subnet_ids
  ecs_cluster_id              = module.foundation.ecs_cluster_id
  ecs_cluster_arn             = module.foundation.ecs_cluster_arn
  ecs_security_group_id       = module.foundation.ecs_security_group_id
  ecs_task_execution_role_arn = module.foundation.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.foundation.ecs_task_role_arn
  alb_https_listener_arn      = module.foundation.alb_https_listener_arn
  private_alb_listener_arn    = module.foundation.private_alb_listener_arn

  deploy_database            = true
  db_instance_class          = var.db_instance_class
  db_allocated_storage       = var.db_allocated_storage
  db_name                    = var.db_name
  db_username                = var.db_username
  db_multi_az                = var.db_multi_az
  db_backup_retention_period = var.db_backup_retention_period
  db_deletion_protection     = var.db_deletion_protection
  db_skip_final_snapshot     = var.db_skip_final_snapshot

  use_external_task_definitions = var.use_external_task_definitions
  dspace_angular_task_def_arn   = var.dspace_angular_task_def_arn
  dspace_api_task_def_arn       = var.dspace_api_task_def_arn
  dspace_jobs_task_def_arn      = var.dspace_jobs_task_def_arn

  dspace_angular_image = var.dspace_angular_image
  dspace_api_image     = var.dspace_api_image
  dspace_jobs_image    = var.dspace_jobs_image

  dspace_angular_cpu    = var.dspace_angular_cpu
  dspace_angular_memory = var.dspace_angular_memory
  dspace_api_cpu        = var.dspace_api_cpu
  dspace_api_memory     = var.dspace_api_memory
  dspace_jobs_cpu       = var.dspace_jobs_cpu
  dspace_jobs_memory    = var.dspace_jobs_memory

  dspace_angular_task_count = var.dspace_angular_task_count
  dspace_api_task_count     = var.dspace_api_task_count

  dspace_server_url_ssm_arn                  = var.dspace_server_url_ssm_arn
  dspace_server_ssr_url_ssm_arn              = var.dspace_server_ssr_url_ssm_arn
  dspace_ui_url_ssm_arn                      = var.dspace_ui_url_ssm_arn
  dspace_db_url_ssm_arn                      = var.dspace_db_url_ssm_arn
  dspace_db_username_ssm_arn                 = var.dspace_db_username_ssm_arn
  dspace_db_password_ssm_arn                 = var.dspace_db_password_ssm_arn
  dspace_solr_url_ssm_arn                    = var.dspace_solr_url_ssm_arn
  dspace_mail_server_ssm_arn                 = var.dspace_mail_server_ssm_arn
  dspace_mail_port_ssm_arn                   = var.dspace_mail_port_ssm_arn
  dspace_mail_username_ssm_arn               = var.dspace_mail_username_ssm_arn
  dspace_mail_password_ssm_arn               = var.dspace_mail_password_ssm_arn
  dspace_mail_disabled_ssm_arn               = var.dspace_mail_disabled_ssm_arn
  dspace_api_java_opts_ssm_arn               = var.dspace_api_java_opts_ssm_arn
  dspace_jobs_java_opts_ssm_arn              = var.dspace_jobs_java_opts_ssm_arn
  dspace_google_analytics_key_ssm_arn        = var.dspace_google_analytics_key_ssm_arn
  dspace_google_analytics_cron_ssm_arn       = var.dspace_google_analytics_cron_ssm_arn
  dspace_google_analytics_api_secret_ssm_arn = var.dspace_google_analytics_api_secret_ssm_arn
  dspace_rest_host_ssm_arn                   = var.dspace_rest_host_ssm_arn
  dspace_rest_ssr_url_ssm_arn                = var.dspace_rest_ssr_url_ssm_arn
  dspace_angular_node_opts_ssm_arn           = var.dspace_angular_node_opts_ssm_arn

  dspace_api_log_group_name     = var.dspace_api_log_group_name
  dspace_angular_log_group_name = var.dspace_angular_log_group_name
  dspace_jobs_log_group_name    = var.dspace_jobs_log_group_name

  enable_init_tasks                = var.enable_init_tasks
  dspace_admin_email               = var.dspace_admin_email
  dspace_admin_first_name          = var.dspace_admin_first_name
  dspace_admin_last_name           = var.dspace_admin_last_name
  dspace_admin_password_secret_arn = var.dspace_admin_password_secret_arn
  solr_url                         = "http://${module.foundation.private_alb_dns_name}:8983/solr"

  dspace_asset_store_bucket_name = var.dspace_asset_store_bucket_name
  alarm_notification_email       = var.alarm_notification_email
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

  db_secret_arn = module.dspace_app.db_credentials_secret_arn
  db_endpoint   = module.dspace_app.db_instance_endpoint
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
  description = "Private ALB DNS name used for internal DSpace and Solr traffic."
  value       = module.foundation.private_alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.foundation.ecs_cluster_name
}

output "db_endpoint" {
  description = "Managed RDS endpoint."
  value       = module.dspace_app.db_instance_endpoint
}

output "db_credentials_secret_arn" {
  description = "Secrets Manager ARN for the managed RDS credentials."
  value       = module.dspace_app.db_credentials_secret_arn
  sensitive   = true
}

output "init_lambda_function_name" {
  description = "Initialization Lambda name when initialization is enabled."
  value       = module.dspace_app.init_lambda_function_name
}
