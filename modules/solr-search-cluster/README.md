# Solr Search Cluster Module

This module deploys a highly available Apache Solr search cluster on ECS Fargate with optional Zookeeper ensemble for coordination.

## Features

- Multi-node Solr cluster with configurable node count
- Optional Zookeeper ensemble (3 or 5 nodes recommended)
- EFS volumes for persistent data storage
- CloudWatch monitoring and health checks
- CloudWatch Synthetics canaries for availability monitoring
- Service discovery via CloudMap
- Auto-scaling support
- ECR repositories for container images

## Architecture

The Solr cluster uses ECS Fargate for compute, EFS for persistent storage, and CloudMap for service discovery. Each Solr node has a unique DNS name for direct access, and the cluster is accessible via a private Application Load Balancer.

<!-- BEGIN_TF_DOCS -->


## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.solr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_dashboard.solr_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_log_group.solr_fargate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.zookeeper_fargate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_metric_filter.solr_cluster_health_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_cloudwatch_log_metric_filter.solr_connection_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_cloudwatch_log_metric_filter.zookeeper_session_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_cloudwatch_metric_alarm.solr_cluster_health_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.solr_connection_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.solr_cpu_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.solr_memory_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.zookeeper_cpu_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.zookeeper_efs_connections](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.zookeeper_health_check_failures](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.zookeeper_memory_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.zookeeper_session_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.zookeeper_task_count_low](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecr_lifecycle_policy.repositories](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.repositories](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecs_service.solr_fargate_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.zookeeper_fargate_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.solr_fargate_td](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.zookeeper_fargate_td](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_efs_access_point.solr_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_efs_access_point.solr_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_efs_access_point.zookeeper_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_efs_file_system.solr_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_file_system.zookeeper_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.solr_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_efs_mount_target.zookeeper_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_iam_policy.synthetics_canary_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.synthetics_canary_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.synthetics_canary_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_layer_version.solr_ops_layer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | resource |
| [aws_lb_listener_rule.solr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.solr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_s3_bucket.synthetics_artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_versioning.synthetics_artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_secretsmanager_secret.zk](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.zk](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.canary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.solr_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.solr_service_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.zookeeper_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.zookeeper_service_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_service_discovery_instance.solr_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_instance) | resource |
| [aws_service_discovery_service.solr_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_service_discovery_service.solr_individual](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_service_discovery_service.zookeeper](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_service_discovery_service.zookeeper_individual](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_ssm_parameter.db_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.server-ssr-url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.server-url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.solr-url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.ui-url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_synthetics_canary.solr_health](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/synthetics_canary) | resource |
| [aws_vpc_security_group_egress_rule.solr_alb_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.solr_dns_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.solr_https_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.solr_nfs_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.solr_self_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.solr_zookeeper_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.zk_egress_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.solr_http_alb_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.solr_http_canary_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.solr_http_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.solr_http_self_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.zk_client_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.zk_client_solr_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.zk_election_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.zk_follower_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [random_id.bucket_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [archive_file.canary_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.solr_ops_layer_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_network_interface.private_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_interface) | data source |
| [aws_network_interfaces.private_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_interfaces) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret.existing_zk](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_notification_email"></a> [alarm\_notification\_email](#input\_alarm\_notification\_email) | Email address to receive CloudWatch alarm notifications. | `string` | `null` | no |
| <a name="input_alarms_sns_topic_arn"></a> [alarms\_sns\_topic\_arn](#input\_alarms\_sns\_topic\_arn) | SNS topic ARN for CloudWatch alarms | `string` | `""` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to deploy resources in. | `string` | n/a | yes |
| <a name="input_cloudwatch_dashboard_name"></a> [cloudwatch\_dashboard\_name](#input\_cloudwatch\_dashboard\_name) | The name of the CloudWatch dashboard. | `string` | `null` | no |
| <a name="input_db_endpoint"></a> [db\_endpoint](#input\_db\_endpoint) | The database endpoint for the DSpace application. | `string` | n/a | yes |
| <a name="input_db_secret_arn"></a> [db\_secret\_arn](#input\_db\_secret\_arn) | The ARN of the AWS Secrets Manager secret containing the database credentials. | `string` | n/a | yes |
| <a name="input_deploy_zookeeper"></a> [deploy\_zookeeper](#input\_deploy\_zookeeper) | Whether to deploy a Zookeeper service. | `bool` | `false` | no |
| <a name="input_desired_task_count"></a> [desired\_task\_count](#input\_desired\_task\_count) | The desired number of tasks to run in the ECS service. | `number` | `1` | no |
| <a name="input_ecr_repositories"></a> [ecr\_repositories](#input\_ecr\_repositories) | A list of ECR repository names to create. | `list(string)` | <pre>[<br>  "solr"<br>]</pre> | no |
| <a name="input_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#input\_ecs\_cluster\_arn) | The ARN of the ECS cluster (from foundation module). | `string` | n/a | yes |
| <a name="input_ecs_cluster_id"></a> [ecs\_cluster\_id](#input\_ecs\_cluster\_id) | The ID of the ECS cluster (from foundation module). | `string` | n/a | yes |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | The name of the ECS cluster (from foundation module). | `string` | n/a | yes |
| <a name="input_ecs_security_group_id"></a> [ecs\_security\_group\_id](#input\_ecs\_security\_group\_id) | The ID of the ECS service security group. | `string` | n/a | yes |
| <a name="input_ecs_task_execution_role_arn"></a> [ecs\_task\_execution\_role\_arn](#input\_ecs\_task\_execution\_role\_arn) | The ARN of the ECS task execution role. | `string` | n/a | yes |
| <a name="input_ecs_task_role_arn"></a> [ecs\_task\_role\_arn](#input\_ecs\_task\_role\_arn) | The ARN of the ECS task role. | `string` | n/a | yes |
| <a name="input_enable_enhanced_monitoring"></a> [enable\_enhanced\_monitoring](#input\_enable\_enhanced\_monitoring) | Whether to enable enhanced monitoring features. | `bool` | `false` | no |
| <a name="input_enable_event_capture"></a> [enable\_event\_capture](#input\_enable\_event\_capture) | Whether to enable ECS event capture for enhanced monitoring. | `bool` | `false` | no |
| <a name="input_enable_solr_autoscaling"></a> [enable\_solr\_autoscaling](#input\_enable\_solr\_autoscaling) | Enable Solr auto-scaling policies and collection templates | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The deployment environment (e.g., dev, staging, prod). | `string` | n/a | yes |
| <a name="input_max_task_count"></a> [max\_task\_count](#input\_max\_task\_count) | The maximum number of tasks for auto scaling. | `number` | `4` | no |
| <a name="input_organization"></a> [organization](#input\_organization) | The organization name (e.g., jhu). | `string` | `"jhu"` | no |
| <a name="input_private_alb_name"></a> [private\_alb\_name](#input\_private\_alb\_name) | The name of the private ALB (for network interface discovery). | `string` | n/a | yes |
| <a name="input_private_alb_security_group_id"></a> [private\_alb\_security\_group\_id](#input\_private\_alb\_security\_group\_id) | The ID of the private ALB security group. | `string` | n/a | yes |
| <a name="input_private_solr_listener_arn"></a> [private\_solr\_listener\_arn](#input\_private\_solr\_listener\_arn) | The ARN of the private ALB Solr listener (port 8983). | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnet IDs to use for ECS tasks. | `list(string)` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | A name for the project to be used in resource names and tags. | `string` | n/a | yes |
| <a name="input_public_domain"></a> [public\_domain](#input\_public\_domain) | The public domain name for the DSpace application. | `string` | n/a | yes |
| <a name="input_service_discovery_namespace_id"></a> [service\_discovery\_namespace\_id](#input\_service\_discovery\_namespace\_id) | The ID of the CloudMap service discovery namespace. | `string` | n/a | yes |
| <a name="input_service_discovery_namespace_name"></a> [service\_discovery\_namespace\_name](#input\_service\_discovery\_namespace\_name) | The name of the CloudMap service discovery namespace. | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | The ARN of the SNS topic for alarms (from DRCC foundation module). | `string` | `null` | no |
| <a name="input_solr_cluster_policies"></a> [solr\_cluster\_policies](#input\_solr\_cluster\_policies) | Solr cluster auto-scaling policies | <pre>list(object({<br>    replica    = optional(string)<br>    shard      = optional(string)<br>    collection = optional(string)<br>    cores      = optional(string)<br>    node       = optional(string)<br>    strict     = optional(bool)<br>  }))</pre> | <pre>[<br>  {<br>    "collection": "#ANY",<br>    "replica": "1",<br>    "shard": "#EACH",<br>    "strict": false<br>  },<br>  {<br>    "cores": "<5",<br>    "node": "#ANY"<br>  }<br>]</pre> | no |
| <a name="input_solr_collection_templates"></a> [solr\_collection\_templates](#input\_solr\_collection\_templates) | Solr collection templates with auto-recovery settings | <pre>map(object({<br>    numShards         = optional(number)<br>    replicationFactor = optional(number)<br>    autoAddReplicas   = optional(bool)<br>    maxShardsPerNode  = optional(number)<br>  }))</pre> | <pre>{<br>  "dspace_default": {<br>    "autoAddReplicas": true,<br>    "maxShardsPerNode": 2,<br>    "numShards": 1,<br>    "replicationFactor": 3<br>  }<br>}</pre> | no |
| <a name="input_solr_cpu"></a> [solr\_cpu](#input\_solr\_cpu) | The CPU units for the Solr task. | `number` | `2048` | no |
| <a name="input_solr_image_name"></a> [solr\_image\_name](#input\_solr\_image\_name) | The name of the Solr Docker image to use. | `string` | `"solr"` | no |
| <a name="input_solr_image_override"></a> [solr\_image\_override](#input\_solr\_image\_override) | Override the default Solr image with a custom image URI. | `string` | `null` | no |
| <a name="input_solr_image_tag"></a> [solr\_image\_tag](#input\_solr\_image\_tag) | The tag of the Solr Docker image to use. | `string` | `"latest"` | no |
| <a name="input_solr_memory"></a> [solr\_memory](#input\_solr\_memory) | The memory (in MiB) for the Solr task. | `number` | `4096` | no |
| <a name="input_solr_node_count"></a> [solr\_node\_count](#input\_solr\_node\_count) | The number of individual Solr nodes (services) to deploy with DNS-based identities. | `number` | `3` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to resources. | `map(string)` | `{}` | no |
| <a name="input_use_external_task_definitions"></a> [use\_external\_task\_definitions](#input\_use\_external\_task\_definitions) | Whether to use externally managed task definitions instead of module-generated ones. | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC to deploy resources in. | `string` | n/a | yes |
| <a name="input_zk_host_secret_arn"></a> [zk\_host\_secret\_arn](#input\_zk\_host\_secret\_arn) | The ARN of the AWS Secrets Manager secret containing the Zookeeper host information. | `string` | `null` | no |
| <a name="input_zookeeper_cpu"></a> [zookeeper\_cpu](#input\_zookeeper\_cpu) | The CPU units for the Zookeeper task. | `number` | `512` | no |
| <a name="input_zookeeper_image"></a> [zookeeper\_image](#input\_zookeeper\_image) | The Zookeeper Docker image to use. | `string` | `"zookeeper:3.8"` | no |
| <a name="input_zookeeper_memory"></a> [zookeeper\_memory](#input\_zookeeper\_memory) | The memory (in MiB) for the Zookeeper task. | `number` | `1024` | no |
| <a name="input_zookeeper_task_count"></a> [zookeeper\_task\_count](#input\_zookeeper\_task\_count) | The number of Zookeeper tasks to run. Should be odd number (3 or 5) for proper quorum. | `number` | `3` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_dashboard_name"></a> [cloudwatch\_dashboard\_name](#output\_cloudwatch\_dashboard\_name) | The name of the CloudWatch dashboard |
| <a name="output_cloudwatch_dashboard_url"></a> [cloudwatch\_dashboard\_url](#output\_cloudwatch\_dashboard\_url) | The URL of the CloudWatch dashboard |
| <a name="output_ecr_repository_urls"></a> [ecr\_repository\_urls](#output\_ecr\_repository\_urls) | A map of ECR repository names to their URLs |
| <a name="output_service_discovery_namespace_id"></a> [service\_discovery\_namespace\_id](#output\_service\_discovery\_namespace\_id) | The ID of the service discovery namespace |
| <a name="output_service_discovery_namespace_name"></a> [service\_discovery\_namespace\_name](#output\_service\_discovery\_namespace\_name) | The name of the service discovery namespace |
| <a name="output_solr_data_efs_access_point_id"></a> [solr\_data\_efs\_access\_point\_id](#output\_solr\_data\_efs\_access\_point\_id) | The ID of the Solr data EFS access point |
| <a name="output_solr_data_efs_id"></a> [solr\_data\_efs\_id](#output\_solr\_data\_efs\_id) | The ID of the Solr data EFS file system |
| <a name="output_solr_efs_arn"></a> [solr\_efs\_arn](#output\_solr\_efs\_arn) | The ARN of the Solr data EFS file system |
| <a name="output_solr_efs_dns_name"></a> [solr\_efs\_dns\_name](#output\_solr\_efs\_dns\_name) | The DNS name of the Solr data EFS file system |
| <a name="output_solr_efs_id"></a> [solr\_efs\_id](#output\_solr\_efs\_id) | The ID of the Solr data EFS file system (alias) |
| <a name="output_solr_node_efs_access_point_ids"></a> [solr\_node\_efs\_access\_point\_ids](#output\_solr\_node\_efs\_access\_point\_ids) | The IDs of the individual Solr node EFS access points |
| <a name="output_solr_node_efs_access_points"></a> [solr\_node\_efs\_access\_points](#output\_solr\_node\_efs\_access\_points) | Map of Solr node names to their EFS access point IDs and paths |
| <a name="output_solr_service_arn"></a> [solr\_service\_arn](#output\_solr\_service\_arn) | The ARN of the first Solr ECS service |
| <a name="output_solr_service_arns"></a> [solr\_service\_arns](#output\_solr\_service\_arns) | The ARNs of the Solr ECS services |
| <a name="output_solr_service_name"></a> [solr\_service\_name](#output\_solr\_service\_name) | The name of the first Solr ECS service |
| <a name="output_solr_service_names"></a> [solr\_service\_names](#output\_solr\_service\_names) | The names of the Solr ECS services |
| <a name="output_solr_target_group_arn"></a> [solr\_target\_group\_arn](#output\_solr\_target\_group\_arn) | The ARN of the Solr target group |
| <a name="output_zookeeper_1_service_arn"></a> [zookeeper\_1\_service\_arn](#output\_zookeeper\_1\_service\_arn) | The ARN of the first Zookeeper ECS service |
| <a name="output_zookeeper_1_service_name"></a> [zookeeper\_1\_service\_name](#output\_zookeeper\_1\_service\_name) | The name of the first Zookeeper ECS service |
| <a name="output_zookeeper_2_service_arn"></a> [zookeeper\_2\_service\_arn](#output\_zookeeper\_2\_service\_arn) | The ARN of the second Zookeeper ECS service |
| <a name="output_zookeeper_2_service_name"></a> [zookeeper\_2\_service\_name](#output\_zookeeper\_2\_service\_name) | The name of the second Zookeeper ECS service |
| <a name="output_zookeeper_3_service_arn"></a> [zookeeper\_3\_service\_arn](#output\_zookeeper\_3\_service\_arn) | The ARN of the third Zookeeper ECS service |
| <a name="output_zookeeper_3_service_name"></a> [zookeeper\_3\_service\_name](#output\_zookeeper\_3\_service\_name) | The name of the third Zookeeper ECS service |
| <a name="output_zookeeper_data_efs_access_point_id"></a> [zookeeper\_data\_efs\_access\_point\_id](#output\_zookeeper\_data\_efs\_access\_point\_id) | The ID of the Zookeeper data EFS access point |
| <a name="output_zookeeper_data_efs_id"></a> [zookeeper\_data\_efs\_id](#output\_zookeeper\_data\_efs\_id) | The ID of the Zookeeper data EFS file system |
| <a name="output_zookeeper_secret_arn"></a> [zookeeper\_secret\_arn](#output\_zookeeper\_secret\_arn) | The ARN of the Secrets Manager secret for the Zookeeper host |
| <a name="output_zookeeper_service_arn"></a> [zookeeper\_service\_arn](#output\_zookeeper\_service\_arn) | The ARN of the Zookeeper ECS service |
| <a name="output_zookeeper_service_name"></a> [zookeeper\_service\_name](#output\_zookeeper\_service\_name) | The name of the Zookeeper ECS service |
<!-- END_TF_DOCS -->

## Examples

See the [examples](../../examples/) directory for complete usage examples:
- [With Solr](../../examples/with-solr/) - Foundation + Solr cluster
- [Complete](../../examples/complete/) - Full DSpace deployment with Solr

## Task Definition Management

This module supports two modes for managing ECS task definitions, controlled by the `use_external_task_definitions` variable.

### Mode 1: External Task Definitions

Set `use_external_task_definitions = true` to manage task definitions outside Terraform (e.g., via CI/CD pipelines). This allows image updates without Terraform drift.

**Required Variables:**
- `solr_task_def_arns` - List of ARNs for Solr node task definitions (length must match `solr_node_count`)
- `zookeeper_task_def_arns` - List of ARNs for Zookeeper node task definitions (required if `deploy_zookeeper = true`)

**Example:**
```hcl
use_external_task_definitions = true
solr_node_count               = 3
solr_task_def_arns = [
  "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-solr-1:25",
  "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-solr-2:25",
  "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-solr-3:25"
]

deploy_zookeeper = true
zookeeper_task_def_arns = [
  "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-zookeeper-1:18",
  "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-zookeeper-2:18",
  "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-zookeeper-3:18"
]
```

### Mode 2: Terraform-Managed Task Definitions (Default)

Set `use_external_task_definitions = false` (default) to let Terraform create and manage task definitions. Useful for initial setup or environments without CI/CD pipelines.

**Required Variables:**
- `solr_image` - Docker image URI for Solr
- `solr_efs_file_system_id` - EFS file system ID for Solr data volumes
- `zookeeper_host_ssm_arn` - ARN of SSM parameter containing Zookeeper host information
- `db_credentials_ssm_arn` - ARN of SSM parameter containing database credentials
- `zookeeper_image` - Docker image URI for Zookeeper (if `deploy_zookeeper = true`)
- `zookeeper_efs_file_system_id` - EFS file system ID for Zookeeper data (if `deploy_zookeeper = true`)

**Optional Variables:**
- `solr_cpu` / `solr_memory` - Resource allocation (defaults: 2048 CPU, 16384 MB)
- `solr_opts` - JVM tuning parameters (default: "-Xms8g -Xmx8g")
- `zookeeper_cpu` / `zookeeper_memory` - Resource allocation (defaults: 512 CPU, 1024 MB)
- `zookeeper_jvmflags` - JVM tuning parameters for Zookeeper

**Example:**
```hcl
use_external_task_definitions = false

# Solr configuration
solr_image              = "123456789012.dkr.ecr.us-east-1.amazonaws.com/solr:9.4.0"
solr_node_count         = 3
solr_cpu                = 2048
solr_memory             = 16384
solr_opts               = "-Xms12g -Xmx12g"  # Production tuning
solr_efs_file_system_id = "fs-0123456789abcdef0"

# Zookeeper configuration
deploy_zookeeper             = true
zookeeper_image              = "123456789012.dkr.ecr.us-east-1.amazonaws.com/zookeeper:3.9"
zookeeper_task_count         = 3
zookeeper_cpu                = 512
zookeeper_memory             = 1024
zookeeper_jvmflags           = "-Xms512m -Xmx512m"
zookeeper_efs_file_system_id = "fs-0fedcba9876543210"

# SSM parameter ARNs
zookeeper_host_ssm_arn = "arn:aws:ssm:us-east-1:123456789012:parameter/dspace/prod/zk-host"
db_credentials_ssm_arn = "arn:aws:ssm:us-east-1:123456789012:parameter/dspace/prod/db-credentials"
```

### JVM Tuning Recommendations

**Solr (`solr_opts`):**
- **Development/Stage:** `-Xms8g -Xmx8g` (8GB heap)
- **Production:** `-Xms12g -Xmx12g` (12GB heap) or higher based on workload
- Ensure heap size is ~50-75% of container memory allocation
- Additional options: `-XX:+UseG1GC -XX:MaxGCPauseMillis=200`

**Zookeeper (`zookeeper_jvmflags`):**
- **Development/Stage:** `-Xms512m -Xmx512m` (512MB heap)
- **Production:** `-Xms1g -Xmx1g` (1GB heap)
- Zookeeper is less memory-intensive than Solr

### Lifecycle Policies

Task definitions include `lifecycle { ignore_changes = [container_definitions] }` to prevent Terraform from detecting drift when CI/CD pipelines update container images. Non-image configuration changes (CPU, memory, volumes) still trigger Terraform updates.

## Migration Guide

### Migrating from External to Terraform-Managed Task Definitions

**Step 1: Prepare Configuration**

Add required variables to your `.tfvars` file:

```hcl
use_external_task_definitions = false

# Solr configuration
solr_image              = "123456789012.dkr.ecr.us-east-1.amazonaws.com/solr:9.4.0"
solr_node_count         = 3
solr_cpu                = 2048
solr_memory             = 16384
solr_opts               = "-Xms12g -Xmx12g"
solr_efs_file_system_id = "fs-0123456789abcdef0"

# Zookeeper configuration (if deployed)
deploy_zookeeper             = true
zookeeper_image              = "123456789012.dkr.ecr.us-east-1.amazonaws.com/zookeeper:3.9"
zookeeper_task_count         = 3
zookeeper_cpu                = 512
zookeeper_memory             = 1024
zookeeper_jvmflags           = "-Xms512m -Xmx512m"
zookeeper_efs_file_system_id = "fs-0fedcba9876543210"

# SSM parameter ARNs
zookeeper_host_ssm_arn = "arn:aws:ssm:us-east-1:123456789012:parameter/dspace/prod/zk-host"
db_credentials_ssm_arn = "arn:aws:ssm:us-east-1:123456789012:parameter/dspace/prod/db-credentials"
```

**Step 2: Create SSM Parameters**

Ensure required SSM parameters exist:

```bash
aws ssm put-parameter --name /dspace/prod/zk-host \
  --value "zookeeper-1.dspace-prod.local:2181,zookeeper-2.dspace-prod.local:2181,zookeeper-3.dspace-prod.local:2181" \
  --type SecureString

aws ssm put-parameter --name /dspace/prod/db-credentials \
  --value "arn:aws:secretsmanager:us-east-1:123456789012:secret:dspace-db-credentials" \
  --type SecureString
```

**Step 3: Plan and Apply**

```bash
terraform plan -var-file=prod.tfvars
# Review: Should show task definition resources being created (3 Solr + 3 Zookeeper)
# Services should show no changes (task_definition ignored by lifecycle)

terraform apply -var-file=prod.tfvars
```

**Step 4: Update CI/CD Pipelines**

Modify workflows to register new revisions using Terraform-managed family names:

```bash
# Example: Update Solr node 1 task definition
aws ecs register-task-definition \
  --family jhu-prod-solr-1 \
  --cli-input-json file://solr-1-task-def.json

# Update service
aws ecs update-service \
  --cluster dspace-prod-cluster \
  --service dspace-prod-solr-1-service \
  --task-definition jhu-prod-solr-1:26
```

### Migrating from Terraform-Managed to External Task Definitions

**Step 1: Export Current Task Definitions**

```bash
# Export all Solr node task definitions
for i in 1 2 3; do
  aws ecs describe-task-definition \
    --task-definition jhu-prod-solr-$i \
    --query 'taskDefinition' > solr-$i-task-def.json
done

# Export Zookeeper task definitions (if deployed)
for i in 1 2 3; do
  aws ecs describe-task-definition \
    --task-definition jhu-prod-zookeeper-$i \
    --query 'taskDefinition' > zookeeper-$i-task-def.json
done
```

**Step 2: Update Configuration**

```hcl
use_external_task_definitions = true

# Provide current task definition ARNs
solr_task_def_arns = [
  "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-solr-1:25",
  "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-solr-2:25",
  "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-solr-3:25"
]

zookeeper_task_def_arns = [
  "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-zookeeper-1:18",
  "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-zookeeper-2:18",
  "arn:aws:ecs:us-east-1:123456789012:task-definition/jhu-prod-zookeeper-3:18"
]

# Remove Terraform-managed variables (no longer needed)
# solr_image = ...
# zookeeper_image = ...
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

Store task definition JSON files in version control and configure CI/CD to manage them independently.

### Rollback Instructions

If issues occur after migration:

**From Terraform-Managed Back to External:**
1. Get current task definition ARNs from ECS console
2. Update `.tfvars` with `use_external_task_definitions = true` and the ARN lists
3. Run `terraform apply` - Terraform destroys its task definitions but services continue using the ARNs

**From External Back to Terraform-Managed:**
1. Ensure all SSM parameters and EFS file systems exist
2. Update `.tfvars` with `use_external_task_definitions = false` and required variables
3. Run `terraform apply` - Terraform creates new task definitions
4. Services continue using external ARNs until next deployment (lifecycle policy prevents automatic updates)
5. Manually update services to use new Terraform-managed task definitions if needed

### CI/CD Compatibility

Both modes support CI/CD workflows:

- **External Mode:** CI/CD registers task definitions and updates services directly
- **Terraform-Managed Mode:** CI/CD registers new revisions of Terraform-managed families, then updates services

The `lifecycle { ignore_changes = [container_definitions] }` policy ensures Terraform doesn't interfere with CI/CD image updates in either mode.

## Configuration Recommendations

### Development
```hcl
use_external_task_definitions = false
solr_node_count               = 1
deploy_zookeeper              = false  # Use embedded Zookeeper
solr_cpu                      = 1024
solr_memory                   = 2048
solr_opts                     = "-Xms1g -Xmx1g"
```

### Production
```hcl
use_external_task_definitions = false  # or true with CI/CD
solr_node_count               = 5      # Odd number for quorum
deploy_zookeeper              = true
zookeeper_task_count          = 3      # 3 or 5 recommended
solr_cpu                      = 4096
solr_memory                   = 16384
solr_opts                     = "-Xms12g -Xmx12g"
zookeeper_jvmflags            = "-Xms1g -Xmx1g"
```

## Notes

- Requires the `drcc-foundation` module to be deployed first
- Solr nodes are numbered starting from 1 (solr-1, solr-2, etc.)
- Zookeeper nodes are also numbered starting from 1
- EFS volumes are encrypted at rest and in transit
- Health checks monitor both Solr and Zookeeper availability

## Production Deployment

For production configuration, security hardening, scaling guidance, and operational procedures, see the [Production Deployment Guide](../../examples/complete/PRODUCTION.md).
