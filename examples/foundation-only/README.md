# Foundation Only Example

This example deploys shared infrastructure without application services or a database.

## Included

- VPC, public/private subnets, and NAT routing
- Public and private Application Load Balancers
- ECS cluster, shared IAM roles, and security groups
- WAF, CloudWatch monitoring, Route 53 private DNS, and Cloud Map
- ACM certificate creation or an existing certificate attachment

RDS ownership belongs to `dspace-app-services`; the foundation module intentionally does not create a database.

## Usage

```bash
cp dev.tfvars.example dev.tfvars
# Replace the example public domain and review the network ranges.

tofu init
tofu plan -var-file=dev.tfvars -out=dev.tfplan
tofu apply dev.tfplan
```

The sample requires a pre-issued, validated ACM certificate ARN. To create a certificate through foundation instead, set `create_ssl_certificate = true`, create the returned DNS validation records, wait for ACM status `ISSUED`, and then apply the listener through a reviewed full plan.

## Downstream modules

Use the foundation outputs to compose Solr, DSpace, Repository MCP, or another ECS service. When a downstream task must read a secret outside the foundation-managed naming patterns, pass that ARN through `ecs_task_execution_secret_arns`. Each reciprocal security-group rule must have one Terraform state owner.
