# DSpace App Services Module
# This module contains the DSpace application services (Angular UI, API, Jobs)
# and related resources like EventBridge scheduled jobs and GitHub Actions roles.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
