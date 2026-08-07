# Repository MCP Service Module

This module deploys the JScholarship/JHRDR Model Context Protocol service on shared DRCC foundation infrastructure.

## Features

- Hardened ARM64 ECS Fargate task definition, or an externally managed task definition
- Dedicated least-privilege task security group with explicit repository backend access
- Host-based routing through the foundation-managed public ALB
- Health checks, deployment circuit breaker, ECS Exec, and read-only root filesystem
- CPU and ALB request-count target tracking
- Optional SNS-backed alarms for availability, latency, CPU, and target 5xx errors
- Migration-compatible resource-name override

## Ownership Boundaries

This application module owns its ECS service, optional task definition, log group, target group, listener rule, task security group, reciprocal public-ALB/backend access rules, autoscaling, and alarms. It intentionally does not create an ECS cluster, ECR repository, IAM roles, ALB, listeners, certificate, WAF, or SNS topic. Those shared resources remain owned by `drcc-foundation` or the deployment composition. Manage each reciprocal rule from one Terraform state only; do not declare equivalent rules around caller-owned SGs elsewhere. Upgrade this module together with a foundation release that removes unrestricted public-ALB egress.

The public ALB can have only one WAF association, so MCP traffic inherits the foundation ACL. For machine-client compatibility, either configure an exact `waf_approved_non_browser_user_agent` or set `waf_block_non_browser_user_agents = false` in `drcc-foundation`; managed rules, application-level host/body validation, and rate limiting still apply. Set `waf_rate_limit_per_ip = 300` if the source stack's global limit is appropriate for all applications sharing the ALB.

The shared listener's default certificate must cover `public_hostname`. If it does not, pass a distinct certificate through `public_alb_certificate_arn` and this module will attach it to the listener. Set the foundation `alb_idle_timeout` to at least `65` seconds for parity with the standalone MCP stack.

## Usage

```hcl
module "repository_mcp" {
  source = "github.com/jhu-library-devops/terraform-aws-jhu-drcc//modules/repository-mcp-service?ref=<release-tag>"

  organization = "jhu"
  project_name = "repository-mcp"
  environment  = "prod"

  vpc_id             = module.foundation.vpc_id
  vpc_cidr_block     = module.foundation.vpc_cidr
  private_subnet_ids = module.foundation.private_subnet_ids

  ecs_cluster_id              = module.foundation.ecs_cluster_id
  ecs_cluster_name            = module.foundation.ecs_cluster_name
  ecs_task_execution_role_arn = module.foundation.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.foundation.ecs_task_role_arn

  public_alb_https_listener_arn = module.foundation.alb_https_listener_arn
  public_alb_security_group_id  = module.foundation.alb_security_group_id
  public_alb_arn_suffix         = module.foundation.alb_arn_suffix
  # Set only when the listener's default certificate does not cover public_hostname.
  public_alb_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/replace-if-needed"

  jscholarship_solr_security_group_id = module.foundation.private_alb_security_group_id
  jscholarship_api_security_group_id  = module.foundation.private_alb_security_group_id

  mcp_image              = "123456789012.dkr.ecr.us-east-1.amazonaws.com/repository-mcp@sha256:replace-with-digest"
  public_hostname        = "mcp.example.edu"
  listener_rule_priority = 200

  jscholarship_solr_url   = "http://solr.dspace.prod.local:8983/solr/search"
  jscholarship_api_url    = "http://${module.foundation.private_alb_dns_name}/server/api"
  jscholarship_public_url = "https://jscholarship.example.edu"

  alarm_sns_topic_arn = module.foundation.sns_topic_arn
}
```

## Task Definition Management

The default mode creates a Terraform-managed task definition from `mcp_image` and the repository endpoint inputs. Set `use_external_task_definitions = true` and provide `mcp_task_def_arn` when CI/CD owns task-definition revisions. External definitions must use the configured `container_name` and `container_port` because the ECS service load-balancer attachment references both values.

The ECS service ignores desired-count drift so Application Auto Scaling remains authoritative. Task-definition changes are not ignored: changes to a Terraform-managed definition or to `mcp_task_def_arn` roll out through the ECS deployment circuit breaker. A CI/CD pipeline that updates the ECS service directly must also update the ARN supplied to Terraform, or the next plan will report drift.

## Migration from `jh-repositories-mcp/infra`

This is a state migration, not a create-before-destroy deployment. Preserve evidence with `tofu state pull` and a saved plan before changing ownership.

1. Back up both states with `tofu state pull`, record the currently deployed task definition and DNS target, and retain saved plan artifacts.
2. Prepare the foundation ALB first: verify certificate coverage, configure its WAF for MCP machine clients, and ensure application catch-all listener rules have lower precedence than the MCP host rule. This library reserves priority `50000` for the DSpace UI catch-all.
3. Use the module's default new names for a blue/green deployment. Do not state-move the legacy ECS service or listener rule: changing ECS clusters cannot occur in place, and moving the rule to the shared listener requires replacement. The legacy shared log group also cannot be moved to both environment-specific module instances.
4. Deploy the new service and target group alongside the legacy stack, test readiness and MCP requests through the shared ALB with the intended Host header, then cut DNS over only after alarms and WAF behavior are verified.
5. Keep the legacy ALB, WAF association, service, cluster, and DNS target until the new path is healthy. Retire them in a separate change only after reviewing a destroy plan that lists every dependent resource.
6. Keep the ECR repository externally owned and pass an immutable image URI through `mcp_image`. Import individual resources only when their AWS identity and ownership are genuinely unchanged; `resource_name_prefix` exists for those controlled cases, not as a substitute for blue/green migration.

Because state layouts differ by deployment, this module does not include hardcoded `moved` blocks. Use `tofu state mv` only within one state and only for identity-preserving moves; use declarative `import` blocks or reviewed state-transfer procedures between state files.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_appautoscaling_policy.cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.requests](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.mcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.mcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.high_cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.high_latency](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.target_5xx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.unhealthy_tasks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecs_service.mcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.mcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_lb_listener_certificate.mcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_lb_listener_rule.mcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.mcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.mcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.mcp_to_dns_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.mcp_to_dns_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.mcp_to_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.mcp_to_jhrdr_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.mcp_to_jhrdr_solr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.mcp_to_jscholarship_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.mcp_to_jscholarship_solr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.public_alb_to_mcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.jhrdr_api_from_mcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.jhrdr_solr_from_mcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.jscholarship_api_from_mcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.jscholarship_solr_from_mcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.mcp_from_public_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [terraform_data.validate_configuration](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alarm_sns_topic_arn"></a> [alarm\_sns\_topic\_arn](#input\_alarm\_sns\_topic\_arn) | Optional SNS topic ARN for MCP CloudWatch alarms. Null disables alarm creation. | `string` | `null` | no |
| <a name="input_autoscaling_cpu_target"></a> [autoscaling\_cpu\_target](#input\_autoscaling\_cpu\_target) | Target average ECS CPU utilization percentage. | `number` | `70` | no |
| <a name="input_autoscaling_requests_per_target"></a> [autoscaling\_requests\_per\_target](#input\_autoscaling\_requests\_per\_target) | Target ALB requests per task used by target tracking. | `number` | `100` | no |
| <a name="input_capacity_provider"></a> [capacity\_provider](#input\_capacity\_provider) | Fargate capacity provider. | `string` | `"FARGATE"` | no |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | Container name in the MCP task definition. External task definitions must use the same value. | `string` | `"repository-mcp"` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | Port exposed by the MCP container. | `number` | `3000` | no |
| <a name="input_ecs_cluster_id"></a> [ecs\_cluster\_id](#input\_ecs\_cluster\_id) | Shared ECS cluster ID from the foundation module. | `string` | n/a | yes |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Shared ECS cluster name used by autoscaling and CloudWatch dimensions. | `string` | n/a | yes |
| <a name="input_ecs_task_execution_role_arn"></a> [ecs\_task\_execution\_role\_arn](#input\_ecs\_task\_execution\_role\_arn) | Shared ECS task execution role ARN from the foundation module. | `string` | n/a | yes |
| <a name="input_ecs_task_role_arn"></a> [ecs\_task\_role\_arn](#input\_ecs\_task\_role\_arn) | Shared ECS task role ARN from the foundation module. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment: stage or prod. The prod value is normalized to production for the MCP application. | `string` | n/a | yes |
| <a name="input_jhrdr_api_port"></a> [jhrdr\_api\_port](#input\_jhrdr\_api\_port) | JHRDR API TCP port. | `number` | `8080` | no |
| <a name="input_jhrdr_api_security_group_id"></a> [jhrdr\_api\_security\_group\_id](#input\_jhrdr\_api\_security\_group\_id) | Optional JHRDR API security group ID. Null disables reciprocal JHRDR API rules. | `string` | `null` | no |
| <a name="input_jhrdr_api_url"></a> [jhrdr\_api\_url](#input\_jhrdr\_api\_url) | Internal JHRDR API URL. Empty disables the adapter endpoint. | `string` | `""` | no |
| <a name="input_jhrdr_public_url"></a> [jhrdr\_public\_url](#input\_jhrdr\_public\_url) | Public JHRDR base URL. Empty disables record links for the adapter. | `string` | `""` | no |
| <a name="input_jhrdr_solr_port"></a> [jhrdr\_solr\_port](#input\_jhrdr\_solr\_port) | JHRDR Solr TCP port. | `number` | `8983` | no |
| <a name="input_jhrdr_solr_security_group_id"></a> [jhrdr\_solr\_security\_group\_id](#input\_jhrdr\_solr\_security\_group\_id) | Optional security group ID attached to the endpoint in jhrdr\_solr\_url. Null disables reciprocal JHRDR Solr rules. | `string` | `null` | no |
| <a name="input_jhrdr_solr_url"></a> [jhrdr\_solr\_url](#input\_jhrdr\_solr\_url) | Internal JHRDR Solr URL. Empty disables the adapter endpoint. | `string` | `""` | no |
| <a name="input_jscholarship_api_port"></a> [jscholarship\_api\_port](#input\_jscholarship\_api\_port) | JScholarship API endpoint TCP port; use 80 for the foundation private ALB. | `number` | `80` | no |
| <a name="input_jscholarship_api_security_group_id"></a> [jscholarship\_api\_security\_group\_id](#input\_jscholarship\_api\_security\_group\_id) | Security group ID for the JScholarship API endpoint, normally the DSpace private ALB security group. | `string` | n/a | yes |
| <a name="input_jscholarship_api_url"></a> [jscholarship\_api\_url](#input\_jscholarship\_api\_url) | Internal JScholarship REST API URL. | `string` | n/a | yes |
| <a name="input_jscholarship_public_url"></a> [jscholarship\_public\_url](#input\_jscholarship\_public\_url) | Public JScholarship base URL used for record links. | `string` | n/a | yes |
| <a name="input_jscholarship_solr_port"></a> [jscholarship\_solr\_port](#input\_jscholarship\_solr\_port) | JScholarship Solr TCP port. | `number` | `8983` | no |
| <a name="input_jscholarship_solr_security_group_id"></a> [jscholarship\_solr\_security\_group\_id](#input\_jscholarship\_solr\_security\_group\_id) | Security group ID attached to the endpoint in jscholarship\_solr\_url. Use the private ALB SG for the module's solr service-discovery name, or the Solr task SG for a direct node URL. | `string` | n/a | yes |
| <a name="input_jscholarship_solr_url"></a> [jscholarship\_solr\_url](#input\_jscholarship\_solr\_url) | Internal JScholarship Solr search collection URL. | `string` | n/a | yes |
| <a name="input_listener_rule_priority"></a> [listener\_rule\_priority](#input\_listener\_rule\_priority) | Unique priority for the MCP host-based HTTPS listener rule. | `number` | n/a | yes |
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | Optional CloudWatch log group name override. | `string` | `null` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Optional MCP log level. Defaults to info in prod and debug elsewhere. | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log retention in days. | `number` | `90` | no |
| <a name="input_mcp_image"></a> [mcp\_image](#input\_mcp\_image) | MCP container image URI with an immutable tag or digest, required for Terraform-managed task definitions. | `string` | `null` | no |
| <a name="input_mcp_task_def_arn"></a> [mcp\_task\_def\_arn](#input\_mcp\_task\_def\_arn) | External MCP task definition ARN, required when use\_external\_task\_definitions is true. | `string` | `null` | no |
| <a name="input_organization"></a> [organization](#input\_organization) | Organization identifier used in resource names and tags. | `string` | `"jhu"` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private subnet IDs where MCP Fargate tasks run. | `list(string)` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project identifier used in resource names and tags. | `string` | `"repository-mcp"` | no |
| <a name="input_public_alb_arn_suffix"></a> [public\_alb\_arn\_suffix](#input\_public\_alb\_arn\_suffix) | ARN suffix for the foundation-managed public ALB, used in metrics and request-count autoscaling. | `string` | n/a | yes |
| <a name="input_public_alb_certificate_arn"></a> [public\_alb\_certificate\_arn](#input\_public\_alb\_certificate\_arn) | Optional ACM certificate ARN to add to the shared HTTPS listener when its default certificate does not cover public\_hostname. | `string` | `null` | no |
| <a name="input_public_alb_https_listener_arn"></a> [public\_alb\_https\_listener\_arn](#input\_public\_alb\_https\_listener\_arn) | HTTPS listener ARN for the foundation-managed public ALB. | `string` | n/a | yes |
| <a name="input_public_alb_security_group_id"></a> [public\_alb\_security\_group\_id](#input\_public\_alb\_security\_group\_id) | Security group ID for the foundation-managed public ALB. | `string` | n/a | yes |
| <a name="input_public_hostname"></a> [public\_hostname](#input\_public\_hostname) | Public hostname routed to this MCP service. | `string` | n/a | yes |
| <a name="input_resource_name_prefix"></a> [resource\_name\_prefix](#input\_resource\_name\_prefix) | Optional resource-name override. Use the legacy prefix during state migration to avoid name churn. | `string` | `null` | no |
| <a name="input_service_desired_count"></a> [service\_desired\_count](#input\_service\_desired\_count) | Initial desired MCP task count. | `number` | `1` | no |
| <a name="input_service_max_count"></a> [service\_max\_count](#input\_service\_max\_count) | Maximum MCP task count for autoscaling. | `number` | `6` | no |
| <a name="input_service_min_count"></a> [service\_min\_count](#input\_service\_min\_count) | Minimum MCP task count for autoscaling. | `number` | `1` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with the module's standard tags. | `map(string)` | `{}` | no |
| <a name="input_task_cpu"></a> [task\_cpu](#input\_task\_cpu) | Fargate task CPU units. | `number` | `512` | no |
| <a name="input_task_memory"></a> [task\_memory](#input\_task\_memory) | Fargate task memory in MiB. | `number` | `1024` | no |
| <a name="input_use_external_task_definitions"></a> [use\_external\_task\_definitions](#input\_use\_external\_task\_definitions) | Whether an external pipeline supplies the MCP task definition instead of this module creating it. | `bool` | `false` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | IPv4 VPC CIDR block used to restrict DNS egress from MCP tasks. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for the MCP service and target group. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ecs_service_arn"></a> [ecs\_service\_arn](#output\_ecs\_service\_arn) | ARN of the Repository MCP ECS service. |
| <a name="output_ecs_service_name"></a> [ecs\_service\_name](#output\_ecs\_service\_name) | Name of the Repository MCP ECS service. |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | CloudWatch log group name for Repository MCP containers. |
| <a name="output_mcp_task_definition_arn"></a> [mcp\_task\_definition\_arn](#output\_mcp\_task\_definition\_arn) | ARN of the external or Terraform-managed Repository MCP task definition. |
| <a name="output_mcp_task_definition_family"></a> [mcp\_task\_definition\_family](#output\_mcp\_task\_definition\_family) | Family of the Terraform-managed task definition, or null in external mode. |
| <a name="output_public_endpoint"></a> [public\_endpoint](#output\_public\_endpoint) | Public MCP protocol endpoint. |
| <a name="output_target_group_arn"></a> [target\_group\_arn](#output\_target\_group\_arn) | ARN of the Repository MCP ALB target group. |
| <a name="output_task_security_group_id"></a> [task\_security\_group\_id](#output\_task\_security\_group\_id) | Security group ID attached to Repository MCP tasks. |
<!-- END_TF_DOCS -->
