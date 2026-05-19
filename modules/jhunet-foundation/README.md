# JHUnet Foundation Module

Foundational AWS infrastructure for ECS batch/ETL workloads running on the internal JHU enterprise network (JHUnet).

## Purpose

This module manages the shared infrastructure layer for ECS tasks that connect into JHUnet. Unlike the `drcc-foundation` module (which supports web services with ALBs, public ingress, and service discovery), this module is intentionally slim:

- **No inbound connections** — batch/ETL tasks initiate outbound only
- **No ALB or listeners** — no web traffic routing needed
- **No service discovery** — tasks are not microservices
- **Egress-only security group** — tasks reach internal JHUnet resources and external APIs

## Resources Managed

| Resource | Purpose |
|----------|---------|
| ECS Cluster | Shared Fargate compute for batch jobs |
| Security Group | Egress-only SG for ECS tasks |
| IAM Task Execution Role | Pulls images, writes logs |
| IAM Task Role | Container-assumed role for AWS API access |
| CloudWatch Log Group | Centralized log output for all tasks |

## Usage

All resources already exist in AWS and should be imported into state on first use.

```hcl
module "jhunet_foundation" {
  source = "../../modules/jhunet-foundation"

  project_name = "jhunet"
  environment  = "stage"

  vpc_id             = "vpc-0abc123..."
  private_subnet_ids = ["subnet-0abc...", "subnet-0def..."]
  ecs_cluster_name   = "jhunet-stage-cluster"
}
```

## Import Workflow

```bash
# Initialize with backend config
tofu init -backend-config=backend-stage.hcl

# Import existing resources into state
tofu import -var-file=stage.tfvars \
  'module.jhunet_foundation.aws_ecs_cluster.main' \
  'arn:aws:ecs:us-east-1:ACCOUNT_ID:cluster/CLUSTER_NAME'

tofu import -var-file=stage.tfvars \
  'module.jhunet_foundation.aws_security_group.ecs_tasks' \
  'sg-XXXXXXXX'

tofu import -var-file=stage.tfvars \
  'module.jhunet_foundation.aws_iam_role.ecs_task_execution_role' \
  'ROLE_NAME'

tofu import -var-file=stage.tfvars \
  'module.jhunet_foundation.aws_iam_role.ecs_task_role' \
  'ROLE_NAME'

tofu import -var-file=stage.tfvars \
  'module.jhunet_foundation.aws_cloudwatch_log_group.ecs_tasks' \
  '/ecs/jhunet-stage'

# Verify — should show no changes if config matches existing resources
tofu plan -var-file=stage.tfvars
```
