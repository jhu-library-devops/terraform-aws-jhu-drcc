# Local values for the DSpace app services module

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name = "${var.project_name}-${var.environment}"

  tags = {
    Name        = local.name
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "OpenTofu"
  }

  db_secret_arn_final = var.db_credentials_secret_arn_override != null ? var.db_credentials_secret_arn_override : (
    var.deploy_database ? aws_secretsmanager_secret.db[0].arn : null
  )
}
