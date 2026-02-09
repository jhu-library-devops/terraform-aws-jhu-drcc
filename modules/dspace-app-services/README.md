# DSpace App Services Module

This module deploys the DSpace 7+ application services including the Angular UI, REST API, and background jobs on ECS Fargate.

## Features

- DSpace Angular UI service (frontend)
- DSpace REST API service (backend)
- DSpace background jobs service (cron tasks)
- S3 buckets for asset storage and statistics
- EventBridge scheduled tasks for maintenance
- GitHub Actions OIDC integration for CI/CD
- CloudWatch dashboards for application monitoring
- Application Load Balancer target groups and listener rules

## Architecture

The DSpace application is deployed as three separate ECS services:
1. **Angular UI** - Serves the frontend application
2. **REST API** - Provides the backend API
3. **Background Jobs** - Runs scheduled maintenance tasks

All services share the same ECS cluster and can scale independently.

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
| [aws_cloudwatch_dashboard.dspace_application](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_event_rule.dspace_jobs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.dspace_jobs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.dspace_angular](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.dspace_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.dspace_jobs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.dspace_api_unavailable](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.dspace_ui_unavailable](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecs_service.admin_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.dspace_angular_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.dspace_api_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_iam_role.eventbridge_ecs_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.github_actions_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.github_actions_test_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.eventbridge_ecs_ssm_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.github_actions_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.eventbridge_ecs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.github_actions_test_admin_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb_listener_rule.private_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.public_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.ui_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.private_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.public_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.ui](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_s3_bucket.dspace_asset_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.statistics_exports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.statistics_exports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.statistics_exports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.dspace_asset_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.statistics_exports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.dspace_asset_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.statistics_exports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.dspace_asset_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.statistics_exports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_sns_topic.dspace_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.email_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_openid_connect_provider.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_notification_email"></a> [alarm\_notification\_email](#input\_alarm\_notification\_email) | Email address for CloudWatch alarm notifications. | `string` | n/a | yes |
| <a name="input_alb_https_listener_arn"></a> [alb\_https\_listener\_arn](#input\_alb\_https\_listener\_arn) | The ARN of the public ALB HTTPS listener. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `"us-east-1"` | no |
| <a name="input_deploy_admin_service"></a> [deploy\_admin\_service](#input\_deploy\_admin\_service) | Whether to deploy the admin service | `bool` | `false` | no |
| <a name="input_dspace_angular_cpu"></a> [dspace\_angular\_cpu](#input\_dspace\_angular\_cpu) | The CPU units for the DSpace Angular task. | `number` | `512` | no |
| <a name="input_dspace_angular_memory"></a> [dspace\_angular\_memory](#input\_dspace\_angular\_memory) | The memory (in MiB) for the DSpace Angular task. | `number` | `1024` | no |
| <a name="input_dspace_angular_task_count"></a> [dspace\_angular\_task\_count](#input\_dspace\_angular\_task\_count) | The number of DSpace Angular tasks to run. | `number` | `1` | no |
| <a name="input_dspace_angular_task_def_arn"></a> [dspace\_angular\_task\_def\_arn](#input\_dspace\_angular\_task\_def\_arn) | The ARN of the ECS Task Definition for DSpace Angular. | `string` | `null` | no |
| <a name="input_dspace_api_cpu"></a> [dspace\_api\_cpu](#input\_dspace\_api\_cpu) | The CPU units for the DSpace API task. | `number` | `1024` | no |
| <a name="input_dspace_api_memory"></a> [dspace\_api\_memory](#input\_dspace\_api\_memory) | The memory (in MiB) for the DSpace API task. | `number` | `2048` | no |
| <a name="input_dspace_api_task_count"></a> [dspace\_api\_task\_count](#input\_dspace\_api\_task\_count) | The number of DSpace API tasks to run. | `number` | `1` | no |
| <a name="input_dspace_api_task_def_arn"></a> [dspace\_api\_task\_def\_arn](#input\_dspace\_api\_task\_def\_arn) | The ARN of the ECS Task Definition for DSpace Api. | `string` | `null` | no |
| <a name="input_dspace_asset_store_bucket_name"></a> [dspace\_asset\_store\_bucket\_name](#input\_dspace\_asset\_store\_bucket\_name) | The name of the S3 bucket for DSpace asset store. | `string` | n/a | yes |
| <a name="input_dspace_jobs_cpu"></a> [dspace\_jobs\_cpu](#input\_dspace\_jobs\_cpu) | The CPU units for the DSpace Jobs task. | `number` | `512` | no |
| <a name="input_dspace_jobs_memory"></a> [dspace\_jobs\_memory](#input\_dspace\_jobs\_memory) | The memory (in MiB) for the DSpace Jobs task. | `number` | `1024` | no |
| <a name="input_dspace_jobs_task_def_arn"></a> [dspace\_jobs\_task\_def\_arn](#input\_dspace\_jobs\_task\_def\_arn) | The ARN of the ECS Task Definition for DSpace Jobs. | `string` | `null` | no |
| <a name="input_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#input\_ecs\_cluster\_arn) | The ARN of the ECS cluster. | `string` | n/a | yes |
| <a name="input_ecs_cluster_id"></a> [ecs\_cluster\_id](#input\_ecs\_cluster\_id) | The ID of the ECS cluster. | `string` | n/a | yes |
| <a name="input_ecs_security_group_id"></a> [ecs\_security\_group\_id](#input\_ecs\_security\_group\_id) | The ID of the ECS security group. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The deployment environment (e.g., stage, prod). | `string` | n/a | yes |
| <a name="input_organization"></a> [organization](#input\_organization) | The organization name (e.g., jhu). | `string` | `"jhu"` | no |
| <a name="input_private_alb_listener_arn"></a> [private\_alb\_listener\_arn](#input\_private\_alb\_listener\_arn) | The ARN of the private ALB HTTP listener. | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnet IDs for ECS services. | `list(string)` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | The name of the project. | `string` | `"dspace"` | no |
| <a name="input_s3_bucket_force_destroy"></a> [s3\_bucket\_force\_destroy](#input\_s3\_bucket\_force\_destroy) | Whether to allow force destruction of the S3 bucket (opposite of deletion protection). | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to resources. | `map(string)` | `{}` | no |
| <a name="input_use_external_task_definitions"></a> [use\_external\_task\_definitions](#input\_use\_external\_task\_definitions) | Whether to use externally managed task definitions instead of module-generated ones. | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dashboard_name"></a> [dashboard\_name](#output\_dashboard\_name) | The name of the CloudWatch dashboard |
| <a name="output_dashboard_url"></a> [dashboard\_url](#output\_dashboard\_url) | The URL to access the CloudWatch dashboard |
| <a name="output_dspace_alerts_topic_arn"></a> [dspace\_alerts\_topic\_arn](#output\_dspace\_alerts\_topic\_arn) | The ARN of the DSpace alerts SNS topic |
| <a name="output_dspace_angular_service_arn"></a> [dspace\_angular\_service\_arn](#output\_dspace\_angular\_service\_arn) | The ARN of the DSpace Angular ECS service |
| <a name="output_dspace_angular_service_name"></a> [dspace\_angular\_service\_name](#output\_dspace\_angular\_service\_name) | The name of the DSpace Angular ECS service |
| <a name="output_dspace_api_service_arn"></a> [dspace\_api\_service\_arn](#output\_dspace\_api\_service\_arn) | The ARN of the DSpace API ECS service |
| <a name="output_dspace_api_service_name"></a> [dspace\_api\_service\_name](#output\_dspace\_api\_service\_name) | The name of the DSpace API ECS service |
| <a name="output_dspace_asset_store_bucket_arn"></a> [dspace\_asset\_store\_bucket\_arn](#output\_dspace\_asset\_store\_bucket\_arn) | The ARN of the DSpace asset store S3 bucket |
| <a name="output_dspace_asset_store_bucket_name"></a> [dspace\_asset\_store\_bucket\_name](#output\_dspace\_asset\_store\_bucket\_name) | The name of the DSpace asset store S3 bucket |
| <a name="output_dspace_config_efs_arn"></a> [dspace\_config\_efs\_arn](#output\_dspace\_config\_efs\_arn) | The ARN of the DSpace config EFS file system (deprecated) |
| <a name="output_dspace_config_efs_dns_name"></a> [dspace\_config\_efs\_dns\_name](#output\_dspace\_config\_efs\_dns\_name) | The DNS name of the DSpace config EFS file system (deprecated) |
| <a name="output_dspace_config_efs_id"></a> [dspace\_config\_efs\_id](#output\_dspace\_config\_efs\_id) | The ID of the DSpace config EFS file system (deprecated) |
| <a name="output_dspace_jobs_task_definition_arn"></a> [dspace\_jobs\_task\_definition\_arn](#output\_dspace\_jobs\_task\_definition\_arn) | The ARN of the DSpace jobs task definition |
| <a name="output_dspace_scheduled_jobs"></a> [dspace\_scheduled\_jobs](#output\_dspace\_scheduled\_jobs) | List of DSpace scheduled job names |
| <a name="output_eventbridge_ecs_role_arn"></a> [eventbridge\_ecs\_role\_arn](#output\_eventbridge\_ecs\_role\_arn) | The ARN of the EventBridge ECS execution role |
| <a name="output_github_actions_role_arn"></a> [github\_actions\_role\_arn](#output\_github\_actions\_role\_arn) | The ARN of the GitHub Actions deployment role |
| <a name="output_github_actions_test_role_arn"></a> [github\_actions\_test\_role\_arn](#output\_github\_actions\_test\_role\_arn) | The ARN of the GitHub Actions test role |
| <a name="output_private_api_target_group_arn"></a> [private\_api\_target\_group\_arn](#output\_private\_api\_target\_group\_arn) | The ARN of the private API target group |
| <a name="output_public_api_target_group_arn"></a> [public\_api\_target\_group\_arn](#output\_public\_api\_target\_group\_arn) | The ARN of the public API target group |
| <a name="output_ui_target_group_arn"></a> [ui\_target\_group\_arn](#output\_ui\_target\_group\_arn) | The ARN of the UI target group |
<!-- END_TF_DOCS -->

## Examples

See the [examples](../../examples/) directory for complete usage examples:
- [Complete](../../examples/complete/) - Full DSpace deployment

## Task Definitions

This module supports two modes for task definitions:

### 1. External Task Definitions (Recommended for CI/CD)
Manage task definitions separately (e.g., via GitHub Actions) and provide the ARNs:

```hcl
dspace_angular_task_def_arn = "arn:aws:ecs:us-east-1:123456789012:task-definition/dspace-angular:5"
dspace_api_task_def_arn     = "arn:aws:ecs:us-east-1:123456789012:task-definition/dspace-api:5"
dspace_jobs_task_def_arn    = "arn:aws:ecs:us-east-1:123456789012:task-definition/dspace-jobs:5"
```

### 2. Module-Managed Task Definitions
Let the module create basic task definitions (useful for initial setup).

## Scaling

Configure the number of tasks for each service:

```hcl
dspace_angular_task_count = 4  # Frontend instances
dspace_api_task_count     = 4  # Backend instances
```

Consider using ECS auto-scaling for production workloads.

## Notes

- Requires the `drcc-foundation` module to be deployed first
- S3 buckets are created for asset storage and statistics exports
- EventBridge rules can be configured for scheduled maintenance tasks
- GitHub Actions OIDC allows secure deployments without long-lived credentials
