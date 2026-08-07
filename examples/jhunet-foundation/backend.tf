# OpenTofu backend configuration for JHUnet foundation infrastructure
#
# Uses partial configuration - specify environment via backend config file:
#   tofu init -backend-config=backend-stage.hcl
#   tofu init -backend-config=backend-prod.hcl -reconfigure
#
# Prerequisites:
# 1. S3 bucket: jhu-drcc-tf-state-bucket (already exists)
# 2. DynamoDB table: jhu-dspace-tf-locks (already exists)

terraform {
  backend "s3" {}
}
