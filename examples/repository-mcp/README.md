# Repository MCP Deployment Example

This example deploys `repository-mcp-service` into an existing DRCC foundation and repository VPC. It replaces the standalone stack's remote-state lookups with explicit module inputs, making dependencies visible in the root composition and plan.

## Prerequisites

- OpenTofu or Terraform >= 1.10 for the included native S3 lockfile backend example
- AWS provider 5.x
- Existing `drcc-foundation` ECS cluster, public ALB HTTPS listener with `alb_idle_timeout >= 65`, IAM roles, VPC, and private subnets
- Existing JScholarship Solr and API endpoint security groups in the same VPC
- Published ARM64 Repository MCP image
- A shared-listener certificate that covers the MCP hostname, or a separate ACM certificate ARN
- A foundation WAF configured with `waf_block_non_browser_user_agents = false` or an exact approved MCP client user agent

## Usage

```bash
cp stage.tfvars.example stage.tfvars
# Replace every example ID, ARN, hostname, URL, and image digest.

tofu init -backend=false
tofu validate
tofu plan -var-file=stage.tfvars -out=stage.tfplan
```

For a remote backend, copy `backend.tf.example` to `backend.tf`, replace `REPLACE_WITH_ENVIRONMENT` and the other placeholders, and initialize with backend access. Use distinct state keys for stage and production; never reuse the unchanged placeholder key.

In a composition that creates the dependencies in the same state, pass outputs directly instead of copying IDs:

```hcl
vpc_id                               = module.foundation.vpc_id
vpc_cidr_block                       = module.foundation.vpc_cidr
private_subnet_ids                   = module.foundation.private_subnet_ids
ecs_cluster_id                       = module.foundation.ecs_cluster_id
ecs_cluster_name                     = module.foundation.ecs_cluster_name
ecs_task_execution_role_arn          = module.foundation.ecs_task_execution_role_arn
ecs_task_role_arn                    = module.foundation.ecs_task_role_arn
public_alb_https_listener_arn         = module.foundation.alb_https_listener_arn
public_alb_security_group_id          = module.foundation.alb_security_group_id
public_alb_arn_suffix                 = module.foundation.alb_arn_suffix
jscholarship_solr_security_group_id   = module.foundation.private_alb_security_group_id
jscholarship_api_security_group_id    = module.foundation.private_alb_security_group_id
alarm_sns_topic_arn                   = module.foundation.sns_topic_arn
```

## Migration Safety

Do not apply this example over the standalone `jh-repositories-mcp/infra` stack until resource ownership has been reconciled. Back up state, route DNS to the shared foundation ALB, import or move retained application resources, and review a saved plan. The old dedicated ALB/WAF and old shared cluster/IAM resources have no direct destinations in this module and must be retired separately.
