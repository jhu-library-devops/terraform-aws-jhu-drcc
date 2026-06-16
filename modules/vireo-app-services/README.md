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
<!-- END_TF_DOCS -->
