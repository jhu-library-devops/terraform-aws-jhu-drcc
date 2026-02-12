# Foundation Only Example

This example deploys only the DRCC foundation infrastructure without any application services.

## What's Included

- VPC with public and private subnets
- Application Load Balancers (public and private)
- RDS PostgreSQL database
- ECS IAM roles and security groups
- CloudWatch monitoring
- WAF configuration
- Route53 private hosted zone
- CloudMap service discovery namespace

## Use Cases

This configuration is useful when:
- Setting up base infrastructure before deploying applications
- Testing infrastructure changes independently
- Using the foundation with custom application deployments
- Deploying applications through separate Terraform workspaces or CI/CD pipelines

## Usage

```bash
terraform init
terraform plan -var="environment=dev"
terraform apply -var="environment=dev"
```

## Next Steps

After deploying the foundation, you can:
1. Deploy Solr cluster using the `with-solr` example
2. Deploy DSpace application services separately
3. Use the outputs to configure external deployments

## Outputs

The module exports all necessary values for downstream modules:
- VPC and subnet IDs
- Security group IDs
- Load balancer ARNs and target groups
- Database endpoint and credentials secret ARN
- IAM role ARNs
