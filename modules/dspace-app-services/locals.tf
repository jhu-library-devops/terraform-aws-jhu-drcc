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

  init_db_secret_arn = var.db_secret_arn != null ? var.db_secret_arn : local.db_secret_arn_final

  db_task_secrets = local.db_secret_arn_final != null ? [
    {
      name      = "db__P__url"
      valueFrom = "${local.db_secret_arn_final}:url::"
    },
    {
      name      = "db__P__username"
      valueFrom = "${local.db_secret_arn_final}:username::"
    },
    {
      name      = "db__P__password"
      valueFrom = "${local.db_secret_arn_final}:password::"
    }
    ] : concat(
    var.dspace_db_url_ssm_arn != null ? [
      { name = "db__P__url", valueFrom = var.dspace_db_url_ssm_arn }
    ] : [],
    var.dspace_db_username_ssm_arn != null ? [
      { name = "db__P__username", valueFrom = var.dspace_db_username_ssm_arn }
    ] : [],
    var.dspace_db_password_ssm_arn != null ? [
      { name = "db__P__password", valueFrom = var.dspace_db_password_ssm_arn }
    ] : []
  )
}
