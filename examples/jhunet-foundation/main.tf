provider "aws" {
  region = var.aws_region
}

module "jhunet_foundation" {
  source = "../../modules/jhunet-foundation"

  organization = var.organization
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # Existing JHUnet VPC and subnets
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids

  # ECS Cluster
  ecs_cluster_name             = var.ecs_cluster_name
  container_insights_value     = var.container_insights_value
  execute_command_logging       = var.execute_command_logging
  service_connect_namespace_arn = var.service_connect_namespace_arn

  # Security
  ecs_security_group_name        = var.ecs_security_group_name
  ecs_security_group_description = var.ecs_security_group_description
  egress_cidr_blocks             = var.egress_cidr_blocks

  # IAM
  ecs_role_name = var.ecs_role_name

  # Logging
  cloudwatch_log_group_name = var.cloudwatch_log_group_name
  log_retention_days        = var.log_retention_days

  # Tags
  tags = var.tags
}
