# Vireo App Services Module

This module deploys a self-contained two-tier ECS Fargate architecture for the Vireo electronic thesis and dissertation (ETD) system. It provisions its own ALBs, WAF, IAM roles, security groups, RDS database, EFS storage, S3 bucket, ECR repository, SSM parameters, SES identity, and CloudWatch monitoring — accepting only shared infrastructure (VPC, ECS cluster, subnets) as input variables.

## Architecture

The Vireo application is deployed as two ECS Fargate services behind a dual-ALB architecture:

1. **Proxy Service** — Shibboleth SP authentication reverse proxy
2. **App Service** — Vireo Spring Boot application

### Traffic Flow

```
Internet → Public ALB (443/HTTPS) → Proxy ECS (8080/HTTP) → Internal ALB (9000/HTTP) → App ECS (9000/HTTP)
```

The public ALB terminates TLS and forwards traffic to the proxy service, which handles Shibboleth authentication. Authenticated requests are forwarded through an internal ALB to the Vireo application. An HTTP→HTTPS redirect listener on port 80 ensures all external traffic is encrypted in transit.

## Usage

```hcl
module "vireo_app_services" {
  source = "../../modules/vireo-app-services"

  # Identity
  organization = "myorg"
  environment  = "prod"
  project_name = "vireo"

  # Shared infrastructure
  vpc_id             = module.foundation.vpc_id
  private_subnet_ids = module.foundation.private_subnet_ids
  public_subnet_ids  = module.foundation.public_subnet_ids
  ecs_cluster_id     = module.foundation.ecs_cluster_id

  # Domain
  public_domain              = "vireo.example.edu"
  ses_email_domain           = "vireo.example.edu"
  internal_hosted_zone_name  = "vireo.internal"

  # ECS task references
  proxy_task_family     = "myorg-prod-vireo-proxy"
  proxy_container_name  = "vireo-proxy"
  app_task_family       = "myorg-prod-vireo-app"
  app_container_name    = "vireo-app"

  # Storage
  vireo_s3_bucket_name = "myorg-prod-vireo-etl"

  tags = {
    Project     = "vireo"
    Environment = "prod"
  }
}
```

## Shibboleth Configuration

Shibboleth SP variables (`shibboleth2_xml`, `shibboleth_attribute_map_xml`, `shibboleth_sp_cert`, `shibboleth_sp_key`) default to `"placeholder"` so the module can be deployed without initial Shibboleth configuration. The corresponding SSM parameters use `lifecycle { ignore_changes = [value] }`, so values should be updated via the AWS Console or CLI after initial deployment.

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.vireo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_cloudwatch_dashboard.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_log_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.alb_internal_5xx_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.alb_proxy_unhealthy_hosts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.alb_public_5xx_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_db_instance.vireo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.vireo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_ecr_repository.vireo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecs_service.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_efs_access_point.vireo_asset_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_efs_file_system.vireo_asset_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.vireo_asset_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_iam_role.app_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.app_task_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.proxy_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.proxy_task_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.app_task_ecs_exec_msgs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.app_task_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.app_task_execution_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.proxy_task_ecs_exec_msgs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.proxy_task_execution_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.proxy_task_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.app_task_execution_base](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.proxy_task_execution_base](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb.internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http_redirect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.internal_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_route53_record.internal_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_s3_bucket.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.vireo_etl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.vireo_etl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.vireo_etl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.vireo_etl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_secretsmanager_secret.vireo_db_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.vireo_db_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.internal_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.public_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.vireo_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.vireo_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.app_egress_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.app_ingress_internal_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.internal_alb_egress_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.internal_alb_ingress_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.proxy_egress_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.proxy_egress_internal_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.proxy_ingress_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.public_alb_egress_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.public_alb_ingress_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.public_alb_ingress_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ses_domain_identity.vireo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_identity) | resource |
| [aws_ssm_parameter.app_auth_service_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_cors_allow_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_db_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_db_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_db_username](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_email_from](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_email_host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_email_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_email_reply_to](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_email_username](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_java_opts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_jwt_duration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_jwt_issuer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_jwt_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_local_authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_reporting_address](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_security_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_spring_profiles_active](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_stomp_debug](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.app_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.proxy_server_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.proxy_vireo_backend_host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.proxy_vireo_backend_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.shibboleth2_xml](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.shibboleth_attribute_map](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.shibboleth_sp_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.shibboleth_sp_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_wafv2_web_acl.vireo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_association.vireo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [random_password.vireo_db](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecs_task_definition.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_task_definition) | data source |
| [aws_ecs_task_definition.proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_task_definition) | data source |
| [aws_elb_service_account.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elb_service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_access_logs_enabled"></a> [alb\_access\_logs\_enabled](#input\_alb\_access\_logs\_enabled) | Whether to enable ALB access logs to S3. Disabled by default. | `bool` | `false` | no |
| <a name="input_alb_access_logs_retention_days"></a> [alb\_access\_logs\_retention\_days](#input\_alb\_access\_logs\_retention\_days) | Number of days to retain ALB access logs in S3. | `number` | `90` | no |
| <a name="input_app_container_name"></a> [app\_container\_name](#input\_app\_container\_name) | The container name in the Vireo app task definition. Required when deploy\_ecs\_services is true. | `string` | `null` | no |
| <a name="input_app_task_family"></a> [app\_task\_family](#input\_app\_task\_family) | The ECS task definition family name for the Vireo app (externally managed). Required when deploy\_ecs\_services is true. | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region. | `string` | `"us-east-1"` | no |
| <a name="input_db_backup_retention_period"></a> [db\_backup\_retention\_period](#input\_db\_backup\_retention\_period) | The days to retain backups for. | `number` | `1` | no |
| <a name="input_db_deletion_protection"></a> [db\_deletion\_protection](#input\_db\_deletion\_protection) | If the DB instance should have deletion protection enabled. | `bool` | `false` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | The instance class for the RDS database. | `string` | `"db.t4g.medium"` | no |
| <a name="input_db_multi_az"></a> [db\_multi\_az](#input\_db\_multi\_az) | Specifies if the RDS instance is multi-AZ. | `bool` | `false` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | The name of the database. | `string` | `"vireo"` | no |
| <a name="input_db_skip_final_snapshot"></a> [db\_skip\_final\_snapshot](#input\_db\_skip\_final\_snapshot) | Determines whether a final DB snapshot is created before deletion. | `bool` | `true` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | The username for the database. | `string` | `"vireo"` | no |
| <a name="input_deploy_database"></a> [deploy\_database](#input\_deploy\_database) | Whether to deploy a new RDS PostgreSQL database. | `bool` | `true` | no |
| <a name="input_deploy_ecs_services"></a> [deploy\_ecs\_services](#input\_deploy\_ecs\_services) | Whether to create the ECS services. Set to false for initial infrastructure provisioning before task definitions are registered. | `bool` | `true` | no |
| <a name="input_ecr_force_delete"></a> [ecr\_force\_delete](#input\_ecr\_force\_delete) | Whether to allow force deletion of the ECR repository (including images). | `bool` | `false` | no |
| <a name="input_ecs_cluster_id"></a> [ecs\_cluster\_id](#input\_ecs\_cluster\_id) | The ID of the shared ECS cluster. | `string` | n/a | yes |
| <a name="input_efs_one_zone_az"></a> [efs\_one\_zone\_az](#input\_efs\_one\_zone\_az) | Availability zone for One Zone EFS storage. Set to null for Multi-AZ (default). | `string` | `null` | no |
| <a name="input_efs_one_zone_subnet_id"></a> [efs\_one\_zone\_subnet\_id](#input\_efs\_one\_zone\_subnet\_id) | Private subnet ID in the One Zone AZ. Required when efs\_one\_zone\_az is set. | `string` | `null` | no |
| <a name="input_enable_enhanced_monitoring"></a> [enable\_enhanced\_monitoring](#input\_enable\_enhanced\_monitoring) | If true, creates the Vireo CloudWatch alarms and dashboard. Alarm actions are wired to sns\_topic\_arn when it is non-null; when null, alarms still create with empty action lists. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The deployment environment. | `string` | n/a | yes |
| <a name="input_internal_hosted_zone_name"></a> [internal\_hosted\_zone\_name](#input\_internal\_hosted\_zone\_name) | The name of the Route53 private hosted zone for the internal ALB (e.g. vireo.internal). | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | The number of days to retain CloudWatch logs. | `number` | `30` | no |
| <a name="input_organization"></a> [organization](#input\_organization) | The organization name. | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnet IDs. | `list(string)` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | The project name used in resource naming and SSM parameter paths. | `string` | `"vireo"` | no |
| <a name="input_proxy_container_name"></a> [proxy\_container\_name](#input\_proxy\_container\_name) | The container name in the proxy task definition. Required when deploy\_ecs\_services is true. | `string` | `null` | no |
| <a name="input_proxy_task_count"></a> [proxy\_task\_count](#input\_proxy\_task\_count) | The number of proxy tasks to run. | `number` | `1` | no |
| <a name="input_proxy_task_family"></a> [proxy\_task\_family](#input\_proxy\_task\_family) | The ECS task definition family name for the proxy (externally managed). Required when deploy\_ecs\_services is true. | `string` | `null` | no |
| <a name="input_public_domain"></a> [public\_domain](#input\_public\_domain) | The public domain name for Vireo (used for ALB host-based routing). | `string` | n/a | yes |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | List of public subnet IDs (for ALB placement). | `list(string)` | n/a | yes |
| <a name="input_s3_bucket_force_destroy"></a> [s3\_bucket\_force\_destroy](#input\_s3\_bucket\_force\_destroy) | Whether to allow force destruction of the S3 bucket. | `bool` | `false` | no |
| <a name="input_ses_email_domain"></a> [ses\_email\_domain](#input\_ses\_email\_domain) | The domain to register as an SES identity for sending email. | `string` | n/a | yes |
| <a name="input_shibboleth2_xml"></a> [shibboleth2\_xml](#input\_shibboleth2\_xml) | Content of shibboleth2.xml configuration file. | `string` | `"placeholder"` | no |
| <a name="input_shibboleth_attribute_map_xml"></a> [shibboleth\_attribute\_map\_xml](#input\_shibboleth\_attribute\_map\_xml) | Content of attribute-map.xml configuration file. | `string` | `"placeholder"` | no |
| <a name="input_shibboleth_sp_cert"></a> [shibboleth\_sp\_cert](#input\_shibboleth\_sp\_cert) | Content of sp-cert.pem (Shibboleth SP certificate). | `string` | `"placeholder"` | no |
| <a name="input_shibboleth_sp_key"></a> [shibboleth\_sp\_key](#input\_shibboleth\_sp\_key) | Content of sp-key.pem (Shibboleth SP private key). | `string` | `"placeholder"` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | The ARN of the shared SNS topic for alarms. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to resources. | `map(string)` | `{}` | no |
| <a name="input_vireo_s3_bucket_name"></a> [vireo\_s3\_bucket\_name](#input\_vireo\_s3\_bucket\_name) | The name of the S3 bucket for Vireo ETL jobs. | `string` | n/a | yes |
| <a name="input_vireo_task_count"></a> [vireo\_task\_count](#input\_vireo\_task\_count) | The number of Vireo tasks to run. | `number` | `1` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the shared VPC. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_arn"></a> [alb\_arn](#output\_alb\_arn) | The ARN of the public ALB |
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | The DNS name of the public ALB (use for Route53 CNAME/alias) |
| <a name="output_alb_zone_id"></a> [alb\_zone\_id](#output\_alb\_zone\_id) | The hosted zone ID of the public ALB (for Route53 alias records) |
| <a name="output_app_log_group_name"></a> [app\_log\_group\_name](#output\_app\_log\_group\_name) | The name of the app CloudWatch log group |
| <a name="output_app_security_group_id"></a> [app\_security\_group\_id](#output\_app\_security\_group\_id) | The ID of the app ECS security group |
| <a name="output_app_service_arn"></a> [app\_service\_arn](#output\_app\_service\_arn) | The ARN of the app ECS service (null when deploy\_ecs\_services is false) |
| <a name="output_app_service_name"></a> [app\_service\_name](#output\_app\_service\_name) | The name of the app ECS service (null when deploy\_ecs\_services is false) |
| <a name="output_app_target_group_arn"></a> [app\_target\_group\_arn](#output\_app\_target\_group\_arn) | The ARN of the app ALB target group (internal) |
| <a name="output_app_task_execution_role_arn"></a> [app\_task\_execution\_role\_arn](#output\_app\_task\_execution\_role\_arn) | The ARN of the app ECS task execution role |
| <a name="output_app_task_role_arn"></a> [app\_task\_role\_arn](#output\_app\_task\_role\_arn) | The ARN of the app ECS task role |
| <a name="output_certificate_arn"></a> [certificate\_arn](#output\_certificate\_arn) | The ARN of the ACM certificate for the public domain |
| <a name="output_certificate_validation_records"></a> [certificate\_validation\_records](#output\_certificate\_validation\_records) | DNS validation records to create for the ACM certificate |
| <a name="output_db_credentials_secret_arn"></a> [db\_credentials\_secret\_arn](#output\_db\_credentials\_secret\_arn) | The ARN of the database credentials secret (null when deploy\_database is false) |
| <a name="output_db_instance_endpoint"></a> [db\_instance\_endpoint](#output\_db\_instance\_endpoint) | The endpoint of the RDS instance (null when deploy\_database is false) |
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | The ARN of the ECR repository |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | The URL of the ECR repository (shared for proxy and app images) |
| <a name="output_efs_access_point_id"></a> [efs\_access\_point\_id](#output\_efs\_access\_point\_id) | The ID of the EFS access point |
| <a name="output_efs_file_system_id"></a> [efs\_file\_system\_id](#output\_efs\_file\_system\_id) | The ID of the EFS file system for the asset store |
| <a name="output_internal_alb_arn"></a> [internal\_alb\_arn](#output\_internal\_alb\_arn) | The ARN of the internal ALB |
| <a name="output_internal_alb_dns_name"></a> [internal\_alb\_dns\_name](#output\_internal\_alb\_dns\_name) | The DNS name of the internal ALB |
| <a name="output_internal_hosted_zone_id"></a> [internal\_hosted\_zone\_id](#output\_internal\_hosted\_zone\_id) | The ID of the Route53 private hosted zone for the internal ALB |
| <a name="output_internal_hosted_zone_name"></a> [internal\_hosted\_zone\_name](#output\_internal\_hosted\_zone\_name) | The name of the Route53 private hosted zone for the internal ALB |
| <a name="output_proxy_log_group_name"></a> [proxy\_log\_group\_name](#output\_proxy\_log\_group\_name) | The name of the proxy CloudWatch log group |
| <a name="output_proxy_security_group_id"></a> [proxy\_security\_group\_id](#output\_proxy\_security\_group\_id) | The ID of the proxy ECS security group |
| <a name="output_proxy_service_arn"></a> [proxy\_service\_arn](#output\_proxy\_service\_arn) | The ARN of the proxy ECS service (null when deploy\_ecs\_services is false) |
| <a name="output_proxy_service_name"></a> [proxy\_service\_name](#output\_proxy\_service\_name) | The name of the proxy ECS service (null when deploy\_ecs\_services is false) |
| <a name="output_proxy_target_group_arn"></a> [proxy\_target\_group\_arn](#output\_proxy\_target\_group\_arn) | The ARN of the proxy ALB target group |
| <a name="output_proxy_task_execution_role_arn"></a> [proxy\_task\_execution\_role\_arn](#output\_proxy\_task\_execution\_role\_arn) | The ARN of the proxy ECS task execution role |
| <a name="output_proxy_task_role_arn"></a> [proxy\_task\_role\_arn](#output\_proxy\_task\_role\_arn) | The ARN of the proxy ECS task role |
| <a name="output_public_alb_security_group_id"></a> [public\_alb\_security\_group\_id](#output\_public\_alb\_security\_group\_id) | The ID of the public ALB security group |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | The ARN of the S3 bucket for ETL jobs |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | The name of the S3 bucket for ETL jobs |
| <a name="output_ses_domain_identity_arn"></a> [ses\_domain\_identity\_arn](#output\_ses\_domain\_identity\_arn) | The ARN of the SES domain identity |
| <a name="output_ses_verification_token"></a> [ses\_verification\_token](#output\_ses\_verification\_token) | The verification token for the SES domain identity. Create a TXT record named \_amazonses.<domain> with this value. |
| <a name="output_waf_web_acl_arn"></a> [waf\_web\_acl\_arn](#output\_waf\_web\_acl\_arn) | The ARN of the WAFv2 Web ACL attached to the public ALB |
<!-- END_TF_DOCS -->
