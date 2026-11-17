# Complete DSpace Deployment Example

This root module composes the three supported DSpace modules:

- `drcc-foundation` creates networking, ALBs, IAM, WAF, ECS, and service discovery.
- `dspace-app-services` owns the PostgreSQL database and DSpace application services.
- `solr-search-cluster` creates Solr, optional Zookeeper, and persistent EFS storage.

The security-group contracts are reciprocal: the public and private ALBs can reach application targets, DSpace can reach RDS and Solr, and Solr can reach Zookeeper, EFS, DNS, and required AWS endpoints.

## Prerequisites

- OpenTofu or Terraform `>= 1.6`
- AWS credentials with permission to create the documented resources
- A public DNS name
- Either permission to create and DNS-validate an ACM certificate or an existing ACM certificate ARN
- Existing SSM parameters when using module-managed DSpace task definitions
- Unique S3 bucket names and production-approved container image references

## Usage

```bash
cp stage.tfvars.example stage.tfvars
# Replace example domains, account IDs, images, SSM ARNs, and notification addresses.

tofu init
tofu plan -var-file=stage.tfvars -out=stage.tfplan
tofu apply stage.tfplan
```

For production, start from `prod.tfvars.example` and review [PRODUCTION.md](./PRODUCTION.md). Apply the reviewed full plan rather than targeting individual modules; targeted applies can leave reciprocal security-group rules or cross-module dependencies incomplete.

## Database ownership

This example sets `deploy_database = true` on `dspace-app-services`. The DSpace module creates RDS, its security group, generated password, and credentials secret. Its database endpoint and secret ARN are passed to Solr. `drcc-foundation` does not create a database.

To use an existing database instead, set `deploy_database = false` in the `dspace_app` module, pass `db_instance_identifier` and `db_credentials_secret_arn_override`, and add the external secret ARN to `foundation.ecs_task_execution_secret_arns` if its name is outside the foundation-managed secret pattern.

## Task-definition modes

The supplied tfvars files use module-managed DSpace task definitions:

```hcl
use_external_task_definitions = false
```

In this mode, all three DSpace image variables are required. For CI/CD-managed task definitions, set the value to `true` and provide all three task-definition ARNs. Do not mix modes.

## Certificate modes

The supplied tfvars files require a pre-issued, validated ACM certificate ARN so the documented full-plan workflow can complete in one pass. To set `create_ssl_certificate = true`, use a staged workflow: request the certificate, create the emitted DNS validation records, wait for ACM status `ISSUED`, and then attach it to the listener in a reviewed full plan.

## Outputs

The root module returns ALB and ECS identifiers, the managed database endpoint and secret ARN, and the optional initialization Lambda name. The database secret ARN output is marked sensitive.

## Cost and safety

This configuration creates NAT gateways, two ALBs, RDS, EFS, ECS/Fargate services, WAF, and monitoring resources. Review the plan and AWS pricing before applying. Production tfvars enable RDS deletion protection, backups, and a final snapshot; staging intentionally uses less protective defaults and must not be treated as production configuration.
