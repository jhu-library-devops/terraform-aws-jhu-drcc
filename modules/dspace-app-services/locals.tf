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
}
