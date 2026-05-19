# JHUnet Foundation — Root Configuration

Root module that deploys the `jhunet-foundation` module with S3 backend state.

## Quick Start

```bash
# Initialize with stage backend
tofu init -backend-config=backend-stage.hcl

# Fill in actual resource IDs in stage.tfvars, then import existing resources
tofu import -var-file=stage.tfvars \
  'module.jhunet_foundation.aws_ecs_cluster.main' \
  'arn:aws:ecs:us-east-1:ACCOUNT_ID:cluster/jhunet-stage-cluster'

tofu import -var-file=stage.tfvars \
  'module.jhunet_foundation.aws_security_group.ecs_tasks' \
  'sg-XXXXXXXX'

tofu import -var-file=stage.tfvars \
  'module.jhunet_foundation.aws_iam_role.ecs_task_execution_role' \
  'jhunet-stage-ecsTaskExecutionRole'

tofu import -var-file=stage.tfvars \
  'module.jhunet_foundation.aws_iam_role.ecs_task_role' \
  'jhunet-stage-ecsTaskRole'

tofu import -var-file=stage.tfvars \
  'module.jhunet_foundation.aws_cloudwatch_log_group.ecs_tasks' \
  '/ecs/jhunet-stage'

# Verify state matches reality
tofu plan -var-file=stage.tfvars
```

## Backend State

| Environment | Key |
|-------------|-----|
| Stage | `jhunet/stage/opentofu.tfstate` |
| Prod | `jhunet/prod/opentofu.tfstate` |

Bucket: `jhu-drcc-tf-state-bucket`
Lock table: `jhu-dspace-tf-locks`
