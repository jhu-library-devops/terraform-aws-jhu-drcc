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
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

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
| [aws_cloudwatch_log_group.init](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.dspace_api_unavailable](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.dspace_ui_unavailable](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_db_instance.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_ecs_service.admin_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.dspace_angular_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.dspace_api_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.dspace_jobs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.db_init](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.dspace_angular](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.dspace_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.dspace_jobs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.solr_init](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_openid_connect_provider.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.eventbridge_ecs_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.github_actions_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.github_actions_test_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.init_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.eventbridge_ecs_ssm_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.github_actions_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.github_actions_test_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.init_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.eventbridge_ecs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.init_lambda_basic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.run_init_tasks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
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
| [aws_secretsmanager_secret.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_sns_topic.dspace_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.email_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_vpc_security_group_ingress_rule.db_ingress_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [random_password.db](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [terraform_data.validate_task_definition_config](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [archive_file.init_lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_openid_connect_provider.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_notification_email"></a> [alarm\_notification\_email](#input\_alarm\_notification\_email) | Email address for CloudWatch alarm notifications. | `string` | n/a | yes |
| <a name="input_alb_https_listener_arn"></a> [alb\_https\_listener\_arn](#input\_alb\_https\_listener\_arn) | The ARN of the public ALB HTTPS listener. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `"us-east-1"` | no |
| <a name="input_create_github_oidc_provider"></a> [create\_github\_oidc\_provider](#input\_create\_github\_oidc\_provider) | Whether to create the GitHub Actions OIDC identity provider. Set to false if the provider already exists in the AWS account. | `bool` | `false` | no |
| <a name="input_db_allocated_storage"></a> [db\_allocated\_storage](#input\_db\_allocated\_storage) | The allocated storage in gigabytes for the RDS database. | `number` | `20` | no |
| <a name="input_db_backup_retention_period"></a> [db\_backup\_retention\_period](#input\_db\_backup\_retention\_period) | The days to retain backups for. Must be > 0 to enable backups. Recommended: 7+ for production. | `number` | `7` | no |
| <a name="input_db_credentials_secret_arn_override"></a> [db\_credentials\_secret\_arn\_override](#input\_db\_credentials\_secret\_arn\_override) | The ARN of an existing Secrets Manager secret containing database credentials. | `string` | `null` | no |
| <a name="input_db_deletion_protection"></a> [db\_deletion\_protection](#input\_db\_deletion\_protection) | If the DB instance should have deletion protection enabled. Should be true for production. | `bool` | `false` | no |
| <a name="input_db_engine_version"></a> [db\_engine\_version](#input\_db\_engine\_version) | The engine version of the RDS instance. | `string` | `"17.4"` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | The instance class for the RDS database. | `string` | `"db.t3.micro"` | no |
| <a name="input_db_instance_identifier"></a> [db\_instance\_identifier](#input\_db\_instance\_identifier) | The identifier of an existing RDS instance to use. Required if `deploy_database` is false. | `string` | `null` | no |
| <a name="input_db_multi_az"></a> [db\_multi\_az](#input\_db\_multi\_az) | Specifies if the RDS instance is multi-AZ. Should be true for production. | `bool` | `false` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | The name of the database to create in the RDS instance. | `string` | `"dspace"` | no |
| <a name="input_db_secret_arn"></a> [db\_secret\_arn](#input\_db\_secret\_arn) | ARN of the Secrets Manager secret containing database credentials | `string` | `null` | no |
| <a name="input_db_secret_rotation_type"></a> [db\_secret\_rotation\_type](#input\_db\_secret\_rotation\_type) | The type of database secret rotation (manual or automatic). | `string` | `"manual"` | no |
| <a name="input_db_skip_final_snapshot"></a> [db\_skip\_final\_snapshot](#input\_db\_skip\_final\_snapshot) | Determines whether a final DB snapshot is created before the DB instance is deleted. Should be false for production. | `bool` | `true` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | The master username for the RDS database. | `string` | `"dspaceuser"` | no |
| <a name="input_deploy_admin_service"></a> [deploy\_admin\_service](#input\_deploy\_admin\_service) | Whether to deploy the admin service | `bool` | `false` | no |
| <a name="input_deploy_database"></a> [deploy\_database](#input\_deploy\_database) | If true, deploys a new RDS PostgreSQL database. If false, the module can use an existing database by providing `db_instance_identifier` and `db_credentials_secret_arn_override`. | `bool` | `false` | no |
| <a name="input_dspace_admin_email"></a> [dspace\_admin\_email](#input\_dspace\_admin\_email) | Email address for the initial DSpace administrator account | `string` | `"admin@example.com"` | no |
| <a name="input_dspace_admin_first_name"></a> [dspace\_admin\_first\_name](#input\_dspace\_admin\_first\_name) | First name for the initial DSpace administrator account | `string` | `"Admin"` | no |
| <a name="input_dspace_admin_last_name"></a> [dspace\_admin\_last\_name](#input\_dspace\_admin\_last\_name) | Last name for the initial DSpace administrator account | `string` | `"User"` | no |
| <a name="input_dspace_admin_password"></a> [dspace\_admin\_password](#input\_dspace\_admin\_password) | Password for the initial DSpace administrator account. Must be changed after first login. | `string` | `null` | no |
| <a name="input_dspace_angular_cpu"></a> [dspace\_angular\_cpu](#input\_dspace\_angular\_cpu) | The CPU units for the DSpace Angular task. | `number` | `2048` | no |
| <a name="input_dspace_angular_image"></a> [dspace\_angular\_image](#input\_dspace\_angular\_image) | Docker image URI for DSpace Angular container | `string` | `null` | no |
| <a name="input_dspace_angular_log_group_name"></a> [dspace\_angular\_log\_group\_name](#input\_dspace\_angular\_log\_group\_name) | CloudWatch log group name for DSpace Angular | `string` | `null` | no |
| <a name="input_dspace_angular_memory"></a> [dspace\_angular\_memory](#input\_dspace\_angular\_memory) | The memory (in MiB) for the DSpace Angular task. | `number` | `4096` | no |
| <a name="input_dspace_angular_node_opts_ssm_arn"></a> [dspace\_angular\_node\_opts\_ssm\_arn](#input\_dspace\_angular\_node\_opts\_ssm\_arn) | ARN of SSM parameter containing NODE\_OPTIONS for DSpace Angular | `string` | `null` | no |
| <a name="input_dspace_angular_task_count"></a> [dspace\_angular\_task\_count](#input\_dspace\_angular\_task\_count) | The number of DSpace Angular tasks to run. | `number` | `1` | no |
| <a name="input_dspace_angular_task_def_arn"></a> [dspace\_angular\_task\_def\_arn](#input\_dspace\_angular\_task\_def\_arn) | The ARN of the ECS Task Definition for DSpace Angular. | `string` | `null` | no |
| <a name="input_dspace_api_cpu"></a> [dspace\_api\_cpu](#input\_dspace\_api\_cpu) | The CPU units for the DSpace API task. | `number` | `2048` | no |
| <a name="input_dspace_api_image"></a> [dspace\_api\_image](#input\_dspace\_api\_image) | Docker image URI for DSpace API container | `string` | `null` | no |
| <a name="input_dspace_api_java_opts_ssm_arn"></a> [dspace\_api\_java\_opts\_ssm\_arn](#input\_dspace\_api\_java\_opts\_ssm\_arn) | ARN of SSM parameter containing JAVA\_OPTS for DSpace API | `string` | `null` | no |
| <a name="input_dspace_api_log_group_name"></a> [dspace\_api\_log\_group\_name](#input\_dspace\_api\_log\_group\_name) | CloudWatch log group name for DSpace API | `string` | `null` | no |
| <a name="input_dspace_api_memory"></a> [dspace\_api\_memory](#input\_dspace\_api\_memory) | The memory (in MiB) for the DSpace API task. | `number` | `4096` | no |
| <a name="input_dspace_api_task_count"></a> [dspace\_api\_task\_count](#input\_dspace\_api\_task\_count) | The number of DSpace API tasks to run. | `number` | `1` | no |
| <a name="input_dspace_api_task_def_arn"></a> [dspace\_api\_task\_def\_arn](#input\_dspace\_api\_task\_def\_arn) | The ARN of the ECS Task Definition for DSpace Api. | `string` | `null` | no |
| <a name="input_dspace_asset_store_bucket_name"></a> [dspace\_asset\_store\_bucket\_name](#input\_dspace\_asset\_store\_bucket\_name) | The name of the S3 bucket for DSpace asset store. | `string` | n/a | yes |
| <a name="input_dspace_db_password_ssm_arn"></a> [dspace\_db\_password\_ssm\_arn](#input\_dspace\_db\_password\_ssm\_arn) | ARN of SSM parameter containing database password | `string` | `null` | no |
| <a name="input_dspace_db_url_ssm_arn"></a> [dspace\_db\_url\_ssm\_arn](#input\_dspace\_db\_url\_ssm\_arn) | ARN of SSM parameter containing database URL | `string` | `null` | no |
| <a name="input_dspace_db_username_ssm_arn"></a> [dspace\_db\_username\_ssm\_arn](#input\_dspace\_db\_username\_ssm\_arn) | ARN of SSM parameter containing database username | `string` | `null` | no |
| <a name="input_dspace_google_analytics_api_secret_ssm_arn"></a> [dspace\_google\_analytics\_api\_secret\_ssm\_arn](#input\_dspace\_google\_analytics\_api\_secret\_ssm\_arn) | ARN of SSM parameter containing Google Analytics API secret | `string` | `null` | no |
| <a name="input_dspace_google_analytics_cron_ssm_arn"></a> [dspace\_google\_analytics\_cron\_ssm\_arn](#input\_dspace\_google\_analytics\_cron\_ssm\_arn) | ARN of SSM parameter containing Google Analytics cron schedule | `string` | `null` | no |
| <a name="input_dspace_google_analytics_key_ssm_arn"></a> [dspace\_google\_analytics\_key\_ssm\_arn](#input\_dspace\_google\_analytics\_key\_ssm\_arn) | ARN of SSM parameter containing Google Analytics key | `string` | `null` | no |
| <a name="input_dspace_jobs_cpu"></a> [dspace\_jobs\_cpu](#input\_dspace\_jobs\_cpu) | The CPU units for the DSpace Jobs task. | `number` | `4096` | no |
| <a name="input_dspace_jobs_image"></a> [dspace\_jobs\_image](#input\_dspace\_jobs\_image) | Docker image URI for DSpace Jobs container | `string` | `null` | no |
| <a name="input_dspace_jobs_java_opts_ssm_arn"></a> [dspace\_jobs\_java\_opts\_ssm\_arn](#input\_dspace\_jobs\_java\_opts\_ssm\_arn) | ARN of SSM parameter containing JAVA\_OPTS for DSpace Jobs | `string` | `null` | no |
| <a name="input_dspace_jobs_log_group_name"></a> [dspace\_jobs\_log\_group\_name](#input\_dspace\_jobs\_log\_group\_name) | CloudWatch log group name for DSpace Jobs | `string` | `null` | no |
| <a name="input_dspace_jobs_memory"></a> [dspace\_jobs\_memory](#input\_dspace\_jobs\_memory) | The memory (in MiB) for the DSpace Jobs task. | `number` | `8192` | no |
| <a name="input_dspace_jobs_task_def_arn"></a> [dspace\_jobs\_task\_def\_arn](#input\_dspace\_jobs\_task\_def\_arn) | The ARN of the ECS Task Definition for DSpace Jobs. | `string` | `null` | no |
| <a name="input_dspace_mail_disabled_ssm_arn"></a> [dspace\_mail\_disabled\_ssm\_arn](#input\_dspace\_mail\_disabled\_ssm\_arn) | ARN of SSM parameter containing mail server disabled flag | `string` | `null` | no |
| <a name="input_dspace_mail_password_ssm_arn"></a> [dspace\_mail\_password\_ssm\_arn](#input\_dspace\_mail\_password\_ssm\_arn) | ARN of SSM parameter containing mail server password | `string` | `null` | no |
| <a name="input_dspace_mail_port_ssm_arn"></a> [dspace\_mail\_port\_ssm\_arn](#input\_dspace\_mail\_port\_ssm\_arn) | ARN of SSM parameter containing mail server port | `string` | `null` | no |
| <a name="input_dspace_mail_server_ssm_arn"></a> [dspace\_mail\_server\_ssm\_arn](#input\_dspace\_mail\_server\_ssm\_arn) | ARN of SSM parameter containing mail server hostname | `string` | `null` | no |
| <a name="input_dspace_mail_username_ssm_arn"></a> [dspace\_mail\_username\_ssm\_arn](#input\_dspace\_mail\_username\_ssm\_arn) | ARN of SSM parameter containing mail server username | `string` | `null` | no |
| <a name="input_dspace_rest_host_ssm_arn"></a> [dspace\_rest\_host\_ssm\_arn](#input\_dspace\_rest\_host\_ssm\_arn) | ARN of SSM parameter containing DSpace REST API host for Angular | `string` | `null` | no |
| <a name="input_dspace_rest_ssr_url_ssm_arn"></a> [dspace\_rest\_ssr\_url\_ssm\_arn](#input\_dspace\_rest\_ssr\_url\_ssm\_arn) | ARN of SSM parameter containing DSpace REST SSR base URL for Angular | `string` | `null` | no |
| <a name="input_dspace_server_ssr_url_ssm_arn"></a> [dspace\_server\_ssr\_url\_ssm\_arn](#input\_dspace\_server\_ssr\_url\_ssm\_arn) | ARN of SSM parameter containing DSpace server SSR URL | `string` | `null` | no |
| <a name="input_dspace_server_url_ssm_arn"></a> [dspace\_server\_url\_ssm\_arn](#input\_dspace\_server\_url\_ssm\_arn) | ARN of SSM parameter containing DSpace server URL | `string` | `null` | no |
| <a name="input_dspace_solr_url_ssm_arn"></a> [dspace\_solr\_url\_ssm\_arn](#input\_dspace\_solr\_url\_ssm\_arn) | ARN of SSM parameter containing Solr server URL | `string` | `null` | no |
| <a name="input_dspace_ui_url_ssm_arn"></a> [dspace\_ui\_url\_ssm\_arn](#input\_dspace\_ui\_url\_ssm\_arn) | ARN of SSM parameter containing DSpace UI URL | `string` | `null` | no |
| <a name="input_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#input\_ecs\_cluster\_arn) | The ARN of the ECS cluster. | `string` | n/a | yes |
| <a name="input_ecs_cluster_id"></a> [ecs\_cluster\_id](#input\_ecs\_cluster\_id) | The ID of the ECS cluster. | `string` | n/a | yes |
| <a name="input_ecs_security_group_id"></a> [ecs\_security\_group\_id](#input\_ecs\_security\_group\_id) | The ID of the ECS security group. | `string` | n/a | yes |
| <a name="input_ecs_task_execution_role_arn"></a> [ecs\_task\_execution\_role\_arn](#input\_ecs\_task\_execution\_role\_arn) | The ARN of the ECS task execution role. | `string` | n/a | yes |
| <a name="input_ecs_task_role_arn"></a> [ecs\_task\_role\_arn](#input\_ecs\_task\_role\_arn) | The ARN of the ECS task role. | `string` | n/a | yes |
| <a name="input_enable_init_tasks"></a> [enable\_init\_tasks](#input\_enable\_init\_tasks) | Enable Lambda function for running initialization tasks (database migration and Solr setup) | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The deployment environment (e.g., stage, prod). | `string` | n/a | yes |
| <a name="input_github_repository"></a> [github\_repository](#input\_github\_repository) | The GitHub repository reference for OIDC federation (e.g., 'my-org/my-repo'). Used in GitHub Actions IAM role trust policies. | `string` | `""` | no |
| <a name="input_organization"></a> [organization](#input\_organization) | The organization name (e.g., jhu). | `string` | `"jhu"` | no |
| <a name="input_private_alb_listener_arn"></a> [private\_alb\_listener\_arn](#input\_private\_alb\_listener\_arn) | The ARN of the private ALB HTTP listener. | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnet IDs for ECS services. | `list(string)` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | The name of the project. | `string` | `"dspace"` | no |
| <a name="input_s3_bucket_force_destroy"></a> [s3\_bucket\_force\_destroy](#input\_s3\_bucket\_force\_destroy) | Whether to allow force destruction of the S3 bucket (opposite of deletion protection). | `bool` | `true` | no |
| <a name="input_solr_url"></a> [solr\_url](#input\_solr\_url) | URL of the Solr server for initialization | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to resources. | `map(string)` | `{}` | no |
| <a name="input_use_external_task_definitions"></a> [use\_external\_task\_definitions](#input\_use\_external\_task\_definitions) | Whether to use externally managed task definitions instead of module-generated ones. | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dashboard_name"></a> [dashboard\_name](#output\_dashboard\_name) | The name of the CloudWatch dashboard |
| <a name="output_dashboard_url"></a> [dashboard\_url](#output\_dashboard\_url) | The URL to access the CloudWatch dashboard |
| <a name="output_db_credentials_secret_arn"></a> [db\_credentials\_secret\_arn](#output\_db\_credentials\_secret\_arn) | The ARN of the database credentials secret |
| <a name="output_db_init_task_definition_arn"></a> [db\_init\_task\_definition\_arn](#output\_db\_init\_task\_definition\_arn) | ARN of the database initialization task definition |
| <a name="output_db_instance_endpoint"></a> [db\_instance\_endpoint](#output\_db\_instance\_endpoint) | The endpoint of the RDS instance |
| <a name="output_db_instance_id"></a> [db\_instance\_id](#output\_db\_instance\_id) | The ID of the RDS instance |
| <a name="output_db_instance_identifier"></a> [db\_instance\_identifier](#output\_db\_instance\_identifier) | The identifier of the RDS instance |
| <a name="output_dspace_alerts_topic_arn"></a> [dspace\_alerts\_topic\_arn](#output\_dspace\_alerts\_topic\_arn) | The ARN of the DSpace alerts SNS topic |
| <a name="output_dspace_angular_service_arn"></a> [dspace\_angular\_service\_arn](#output\_dspace\_angular\_service\_arn) | The ARN of the DSpace Angular ECS service |
| <a name="output_dspace_angular_service_name"></a> [dspace\_angular\_service\_name](#output\_dspace\_angular\_service\_name) | The name of the DSpace Angular ECS service |
| <a name="output_dspace_angular_task_definition_arn"></a> [dspace\_angular\_task\_definition\_arn](#output\_dspace\_angular\_task\_definition\_arn) | ARN of the DSpace Angular task definition (Terraform-managed or external) |
| <a name="output_dspace_angular_task_definition_family"></a> [dspace\_angular\_task\_definition\_family](#output\_dspace\_angular\_task\_definition\_family) | Family name of the DSpace Angular task definition (null when using external task definitions) |
| <a name="output_dspace_api_service_arn"></a> [dspace\_api\_service\_arn](#output\_dspace\_api\_service\_arn) | The ARN of the DSpace API ECS service |
| <a name="output_dspace_api_service_name"></a> [dspace\_api\_service\_name](#output\_dspace\_api\_service\_name) | The name of the DSpace API ECS service |
| <a name="output_dspace_api_task_definition_arn"></a> [dspace\_api\_task\_definition\_arn](#output\_dspace\_api\_task\_definition\_arn) | ARN of the DSpace API task definition (Terraform-managed or external) |
| <a name="output_dspace_api_task_definition_family"></a> [dspace\_api\_task\_definition\_family](#output\_dspace\_api\_task\_definition\_family) | Family name of the DSpace API task definition (null when using external task definitions) |
| <a name="output_dspace_asset_store_bucket_arn"></a> [dspace\_asset\_store\_bucket\_arn](#output\_dspace\_asset\_store\_bucket\_arn) | The ARN of the DSpace asset store S3 bucket |
| <a name="output_dspace_asset_store_bucket_name"></a> [dspace\_asset\_store\_bucket\_name](#output\_dspace\_asset\_store\_bucket\_name) | The name of the DSpace asset store S3 bucket |
| <a name="output_dspace_config_efs_arn"></a> [dspace\_config\_efs\_arn](#output\_dspace\_config\_efs\_arn) | The ARN of the DSpace config EFS file system (deprecated) |
| <a name="output_dspace_config_efs_dns_name"></a> [dspace\_config\_efs\_dns\_name](#output\_dspace\_config\_efs\_dns\_name) | The DNS name of the DSpace config EFS file system (deprecated) |
| <a name="output_dspace_config_efs_id"></a> [dspace\_config\_efs\_id](#output\_dspace\_config\_efs\_id) | The ID of the DSpace config EFS file system (deprecated) |
| <a name="output_dspace_jobs_task_definition_arn"></a> [dspace\_jobs\_task\_definition\_arn](#output\_dspace\_jobs\_task\_definition\_arn) | ARN of the DSpace Jobs task definition (Terraform-managed or external) |
| <a name="output_dspace_jobs_task_definition_family"></a> [dspace\_jobs\_task\_definition\_family](#output\_dspace\_jobs\_task\_definition\_family) | Family name of the DSpace Jobs task definition (null when using external task definitions) |
| <a name="output_dspace_scheduled_jobs"></a> [dspace\_scheduled\_jobs](#output\_dspace\_scheduled\_jobs) | List of DSpace scheduled job names |
| <a name="output_eventbridge_ecs_role_arn"></a> [eventbridge\_ecs\_role\_arn](#output\_eventbridge\_ecs\_role\_arn) | The ARN of the EventBridge ECS execution role |
| <a name="output_github_actions_role_arn"></a> [github\_actions\_role\_arn](#output\_github\_actions\_role\_arn) | The ARN of the GitHub Actions deployment role |
| <a name="output_github_actions_test_role_arn"></a> [github\_actions\_test\_role\_arn](#output\_github\_actions\_test\_role\_arn) | The ARN of the GitHub Actions test role |
| <a name="output_init_lambda_function_name"></a> [init\_lambda\_function\_name](#output\_init\_lambda\_function\_name) | Name of the Lambda function for running initialization tasks |
| <a name="output_private_api_target_group_arn"></a> [private\_api\_target\_group\_arn](#output\_private\_api\_target\_group\_arn) | The ARN of the private API target group |
| <a name="output_public_api_target_group_arn"></a> [public\_api\_target\_group\_arn](#output\_public\_api\_target\_group\_arn) | The ARN of the public API target group |
| <a name="output_solr_init_task_definition_arn"></a> [solr\_init\_task\_definition\_arn](#output\_solr\_init\_task\_definition\_arn) | ARN of the Solr initialization task definition |
| <a name="output_ui_target_group_arn"></a> [ui\_target\_group\_arn](#output\_ui\_target\_group\_arn) | The ARN of the UI target group |
<!-- END_TF_DOCS -->

## Examples

See the [examples](../../examples/) directory for complete usage examples:
- [Complete](../../examples/complete/) - Full DSpace deployment

## Task Definition Management

This module supports two modes for managing ECS task definitions, controlled by the `use_external_task_definitions` variable.

### Mode 1: External Task Definitions (Default)

Set `use_external_task_definitions = true` (default) to manage task definitions outside Terraform (e.g., via CI/CD pipelines). This allows image updates without Terraform drift.

**Required Variables:**
- `dspace_api_task_def_arn` - ARN of externally-managed DSpace API task definition
- `dspace_angular_task_def_arn` - ARN of externally-managed DSpace Angular task definition
- `dspace_jobs_task_def_arn` - ARN of externally-managed DSpace Jobs task definition

**Example:**
```hcl
use_external_task_definitions = true
dspace_api_task_def_arn       = "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-dspace-api:42"
dspace_angular_task_def_arn   = "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-dspace-angular:38"
dspace_jobs_task_def_arn      = "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-dspace-jobs:15"
```

### Mode 2: Terraform-Managed Task Definitions

Set `use_external_task_definitions = false` to let Terraform create and manage task definitions. Useful for initial setup or environments without CI/CD pipelines.

**Required Variables:**
- `dspace_api_image` - Docker image URI for DSpace API
- `dspace_angular_image` - Docker image URI for DSpace Angular
- `dspace_jobs_image` - Docker image URI for DSpace Jobs
- All SSM parameter ARN variables (see SSM Parameters section below)
- `dspace_asset_store_bucket_name` - S3 bucket name for asset storage

**Optional Variables:**
- `dspace_api_cpu` / `dspace_api_memory` - Resource allocation (defaults: 2048 CPU, 4096 MB)
- `dspace_angular_cpu` / `dspace_angular_memory` - Resource allocation (defaults: 2048 CPU, 4096 MB)
- `dspace_jobs_cpu` / `dspace_jobs_memory` - Resource allocation (defaults: 4096 CPU, 8192 MB)
- `dspace_api_log_group_name` - CloudWatch log group (default: auto-generated)
- `dspace_angular_log_group_name` - CloudWatch log group (default: auto-generated)
- `dspace_jobs_log_group_name` - CloudWatch log group (default: auto-generated)

**Example:**
```hcl
use_external_task_definitions = false

# Container images
dspace_api_image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/dspace-api:7.6.1"
dspace_angular_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/dspace-angular:7.6.1"
dspace_jobs_image    = "123456789012.dkr.ecr.us-east-1.amazonaws.com/dspace-api:7.6.1"

# Resource allocation
dspace_api_cpu        = 2048
dspace_api_memory     = 4096
dspace_angular_cpu    = 2048
dspace_angular_memory = 4096
dspace_jobs_cpu       = 4096
dspace_jobs_memory    = 8192

# S3 configuration
dspace_asset_store_bucket_name = "jhu-prod-dspace-assets"

# SSM parameter ARNs (see SSM Parameters section)
dspace_server_url_ssm_arn     = "arn:aws:ssm:us-east-1:123456789012:parameter/dspace/prod/server-url"
dspace_ui_url_ssm_arn         = "arn:aws:ssm:us-east-1:123456789012:parameter/dspace/prod/ui-url"
dspace_db_url_ssm_arn         = "arn:aws:ssm:us-east-1:123456789012:parameter/dspace/prod/db-url"
# ... (see full list below)
```

### SSM Parameters (Required for Terraform-Managed Mode)

When `use_external_task_definitions = false`, provide ARNs for these SSM parameters:

**DSpace API & Jobs:**
- `dspace_server_url_ssm_arn` - DSpace server URL
- `dspace_server_ssr_url_ssm_arn` - DSpace server-side rendering URL
- `dspace_ui_url_ssm_arn` - DSpace UI URL
- `dspace_db_url_ssm_arn` - Database connection URL
- `dspace_db_username_ssm_arn` - Database username
- `dspace_db_password_ssm_arn` - Database password
- `dspace_solr_url_ssm_arn` - Solr server URL
- `dspace_mail_server_ssm_arn` - Mail server hostname
- `dspace_mail_port_ssm_arn` - Mail server port
- `dspace_mail_username_ssm_arn` - Mail server username
- `dspace_mail_password_ssm_arn` - Mail server password
- `dspace_mail_disabled_ssm_arn` - Mail server disabled flag
- `dspace_api_java_opts_ssm_arn` - JAVA_OPTS for API
- `dspace_jobs_java_opts_ssm_arn` - JAVA_OPTS for Jobs
- `dspace_google_analytics_key_ssm_arn` - Google Analytics key (optional)
- `dspace_google_analytics_cron_ssm_arn` - Google Analytics cron schedule (optional)
- `dspace_google_analytics_api_secret_ssm_arn` - Google Analytics API secret (optional)

**DSpace Angular:**
- `dspace_rest_host_ssm_arn` - REST API hostname
- `dspace_rest_ssr_url_ssm_arn` - REST API SSR base URL
- `dspace_angular_node_opts_ssm_arn` - NODE_OPTIONS for Angular

### Lifecycle Policies

Task definitions include `lifecycle { ignore_changes = [container_definitions] }` to prevent Terraform from detecting drift when CI/CD pipelines update container images. Non-image configuration changes (CPU, memory, IAM roles) still trigger Terraform updates.

## Migration Guide

### Migrating from External to Terraform-Managed Task Definitions

**Step 1: Prepare Configuration**

Add required variables to your `.tfvars` file:

```hcl
use_external_task_definitions = false

# Container images (use current versions from external task definitions)
dspace_api_image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/dspace-api:7.6.1"
dspace_angular_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/dspace-angular:7.6.1"
dspace_jobs_image    = "123456789012.dkr.ecr.us-east-1.amazonaws.com/dspace-api:7.6.1"

# Resource allocation (match current task definitions)
dspace_api_cpu        = 2048
dspace_api_memory     = 4096
dspace_angular_cpu    = 2048
dspace_angular_memory = 4096
dspace_jobs_cpu       = 4096
dspace_jobs_memory    = 8192

# S3 configuration
dspace_asset_store_bucket_name = "your-bucket-name"

# SSM parameter ARNs (create these parameters first)
dspace_server_url_ssm_arn     = "arn:aws:ssm:region:account:parameter/path"
dspace_ui_url_ssm_arn         = "arn:aws:ssm:region:account:parameter/path"
# ... (see SSM Parameters section for full list)
```

**Step 2: Create SSM Parameters**

Ensure all required SSM parameters exist with correct values. Use AWS CLI or Console:

```bash
aws ssm put-parameter --name /dspace/prod/server-url \
  --value "https://api.example.com" --type SecureString

aws ssm put-parameter --name /dspace/prod/ui-url \
  --value "https://example.com" --type SecureString
# ... (repeat for all parameters)
```

**Step 3: Plan and Apply**

```bash
terraform plan -var-file=prod.tfvars
# Review: Should show task definition resources being created
# Services should show no changes (task_definition ignored by lifecycle)

terraform apply -var-file=prod.tfvars
```

**Step 4: Update CI/CD Pipelines**

Modify your CI/CD workflows to register new task definition revisions using the Terraform-managed family names:

```bash
# Example: Update task definition with new image
aws ecs register-task-definition \
  --family jhu-prod-dspace-api \
  --cli-input-json file://task-def.json

# Update service to use new revision
aws ecs update-service \
  --cluster dspace-prod-cluster \
  --service jhu-prod-dspace-service \
  --task-definition jhu-prod-dspace-api:43
```

### Migrating from Terraform-Managed to External Task Definitions

**Step 1: Export Current Task Definitions**

```bash
# Get current task definition ARNs from Terraform outputs
terraform output dspace_api_task_definition_arn
terraform output dspace_angular_task_definition_arn
terraform output dspace_jobs_task_definition_arn

# Export task definitions to JSON files
aws ecs describe-task-definition \
  --task-definition jhu-prod-dspace-api \
  --query 'taskDefinition' > dspace-api-task-def.json
```

**Step 2: Update Configuration**

```hcl
use_external_task_definitions = true

# Provide current task definition ARNs
dspace_api_task_def_arn     = "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-dspace-api:42"
dspace_angular_task_def_arn = "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-dspace-angular:38"
dspace_jobs_task_def_arn    = "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-dspace-jobs:15"

# Remove Terraform-managed variables (no longer needed)
# dspace_api_image = ...
# dspace_angular_image = ...
# etc.
```

**Step 3: Plan and Apply**

```bash
terraform plan -var-file=prod.tfvars
# Review: Should show task definition resources being destroyed
# Services should show no changes

terraform apply -var-file=prod.tfvars
```

**Step 4: Set Up External Task Definition Management**

Configure your CI/CD pipeline to manage task definitions independently (e.g., store JSON files in version control, use GitHub Actions to register new revisions).

### Rollback Instructions

If issues occur after migration:

**From Terraform-Managed Back to External:**
1. Note the current task definition ARNs from ECS console
2. Update `.tfvars` with `use_external_task_definitions = true` and the ARNs
3. Run `terraform apply` - Terraform will destroy its task definitions but services continue using the ARNs

**From External Back to Terraform-Managed:**
1. Ensure all SSM parameters exist
2. Update `.tfvars` with `use_external_task_definitions = false` and required variables
3. Run `terraform apply` - Terraform creates new task definitions
4. Services will continue using external ARNs until next deployment (lifecycle policy prevents automatic updates)
5. Manually update services to use new Terraform-managed task definitions if needed

### CI/CD Compatibility

Both modes are compatible with CI/CD pipelines:

- **External Mode:** CI/CD registers task definitions and updates services directly
- **Terraform-Managed Mode:** CI/CD registers new revisions of Terraform-managed families, then updates services

The `lifecycle { ignore_changes = [container_definitions] }` policy ensures Terraform doesn't interfere with CI/CD image updates in either mode.

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

## Production Deployment

For production configuration, security hardening, scaling guidance, and operational procedures, see the [Production Deployment Guide](../../examples/complete/PRODUCTION.md).
