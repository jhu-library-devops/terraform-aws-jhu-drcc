# JHUnet Foundation Module
# Provides foundational AWS infrastructure for ECS batch/ETL workloads
# running on the internal JHU enterprise network (JHUnet).
#
# This module manages existing resources via import — no new infrastructure
# is created. All resources already exist in the target AWS account.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
