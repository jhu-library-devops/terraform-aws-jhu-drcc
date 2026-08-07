# DSpace App Services Module
# This module contains the DSpace application services (Angular UI, API, Jobs)
# and related resources like EventBridge scheduled jobs and GitHub Actions roles.

terraform {
  required_version = ">= 1.6"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
