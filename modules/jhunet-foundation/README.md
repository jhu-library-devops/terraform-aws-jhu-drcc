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

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.ecs_tasks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_iam_role.ecs_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs_role_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.ecs_tasks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.ecs_tasks_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region where resources reside. | `string` | `"us-east-1"` | no |
| <a name="input_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#input\_cloudwatch\_log\_group\_name) | Name for the CloudWatch log group. Defaults to /ecs/{project}-{env}. | `string` | `null` | no |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Name of the ECS cluster. Used for both the resource name and lookups. | `string` | n/a | yes |
| <a name="input_ecs_role_name"></a> [ecs\_role\_name](#input\_ecs\_role\_name) | Name for the ECS IAM role (used as both task execution and task role). | `string` | `null` | no |
| <a name="input_ecs_security_group_description"></a> [ecs\_security\_group\_description](#input\_ecs\_security\_group\_description) | Description for the ECS tasks security group. | `string` | `null` | no |
| <a name="input_ecs_security_group_name"></a> [ecs\_security\_group\_name](#input\_ecs\_security\_group\_name) | Name for the ECS tasks security group. | `string` | `null` | no |
| <a name="input_egress_cidr_blocks"></a> [egress\_cidr\_blocks](#input\_egress\_cidr\_blocks) | CIDR blocks allowed for outbound traffic from ECS tasks. Defaults to all traffic. | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_enable_container_insights"></a> [enable\_container\_insights](#input\_enable\_container\_insights) | Whether to enable CloudWatch Container Insights on the ECS cluster. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The deployment environment (e.g., dev, stage, prod). | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain CloudWatch logs. | `number` | `30` | no |
| <a name="input_organization"></a> [organization](#input\_organization) | The organization name (e.g., jhu). | `string` | `"jhu"` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of existing private subnet IDs for ECS tasks. | `list(string)` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | A name for the project used in resource names and tags. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to all resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the existing JHUnet-connected VPC. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | The ARN of the CloudWatch log group for ECS tasks |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | The name of the CloudWatch log group for ECS tasks |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | The ARN of the ECS cluster |
| <a name="output_ecs_cluster_id"></a> [ecs\_cluster\_id](#output\_ecs\_cluster\_id) | The ID of the ECS cluster |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | The name of the ECS cluster |
| <a name="output_ecs_role_arn"></a> [ecs\_role\_arn](#output\_ecs\_role\_arn) | The ARN of the ECS role (used as both execution and task role) |
| <a name="output_ecs_role_name"></a> [ecs\_role\_name](#output\_ecs\_role\_name) | The name of the ECS role |
| <a name="output_ecs_security_group_id"></a> [ecs\_security\_group\_id](#output\_ecs\_security\_group\_id) | The ID of the ECS tasks security group |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | List of private subnet IDs for ECS tasks |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the JHUnet-connected VPC |
<!-- END_TF_DOCS -->