# Data sources and local values for Solr service
locals {
  name = "${var.project_name}-${var.environment}"
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "OpenTofu" # Compatible with Terraform
  }

  # Service discovery namespace
  private_dns_namespace = var.service_discovery_namespace_name

  # Zookeeper configuration
  zk_service_name       = "zookeeper"
  zk_connection_string  = "${local.zk_service_name}-1.${var.service_discovery_namespace_name}:2181,${local.zk_service_name}-2.${var.service_discovery_namespace_name}:2181,${local.zk_service_name}-3.${var.service_discovery_namespace_name}:2181"

  # Secret ARN resolution
  zk_secret_arn_final = var.deploy_zookeeper ? aws_secretsmanager_secret.zk[0].arn : (var.zk_host_secret_arn != null ? data.aws_secretsmanager_secret.existing_zk[0].arn : null)

  # Computed ECR repository names using organization variable
  ecr_repositories = length(var.ecr_repositories) > 0 ? var.ecr_repositories : [
    "${var.organization}/dspace",
    "${var.organization}/solr",
    "${var.organization}/zookeeper"
  ]

  # Computed Solr image name using organization variable
  solr_image_name = var.solr_image_name != null ? var.solr_image_name : "${var.organization}/solr"

  # Computed Zookeeper image using organization variable
  zookeeper_image = var.zookeeper_image != null ? var.zookeeper_image : "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.organization}/zookeeper:latest"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_secretsmanager_secret" "existing_zk" {
  count = !var.deploy_zookeeper && var.zk_host_secret_arn != null ? 1 : 0
  arn   = var.zk_host_secret_arn
}
