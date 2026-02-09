# JHU DRCC Terraform Modules

Terraform modules for deploying JHU Digital Research and Curation Center (DRCC) infrastructure on AWS.

## Overview

This repository provides reusable Terraform modules for deploying cloud infrastructure on AWS. While initially developed for DSpace 7+ deployments, the modules are designed to be flexible and reusable for other DRCC applications and services.

The modules follow AWS best practices for high availability, monitoring, security, and cost optimization.

## Module Philosophy

The DRCC module library is built on three principles:

1. **Separation of Concerns** - Foundation provides shared infrastructure, applications manage their own resources
2. **Reusability** - Modules can be composed for different applications beyond DSpace
3. **Production-Ready** - Built with monitoring, security, and operational best practices

## Architecture

The infrastructure is organized into three layers:

### 1. drcc-foundation
**Shared infrastructure layer** - Provides foundational AWS resources that can be shared across multiple applications.

**Resources:**
- VPC with public and private subnets
- Application Load Balancers (public and private)
- RDS PostgreSQL database (optional)
- ECS cluster (Fargate)
- IAM roles and security groups
- CloudWatch monitoring and alarms
- WAF web application firewall
- CloudMap service discovery namespace
- Route53 private hosted zone

**Use when:** Setting up base infrastructure for any containerized application on AWS.

### 2. solr-search-cluster
**Solr search application** - Deploys a highly available Solr cluster with Zookeeper coordination.

**Resources:**
- Solr ECS services (multi-node cluster)
- Zookeeper ensemble (optional)
- EFS volumes for data persistence
- ECR repositories for container images
- CloudWatch monitoring and health checks
- Service discovery for node coordination
- Application Load Balancer target group and listener rules

**Use when:** Applications require full-text search capabilities with Apache Solr.

### 3. dspace-app-services
**DSpace application layer** - Deploys the DSpace repository application (Angular UI, REST API, and background jobs).

**Resources:**
- DSpace Angular UI ECS service
- DSpace REST API ECS service
- DSpace background jobs service
- S3 buckets for asset storage
- EventBridge scheduled tasks
- GitHub Actions OIDC integration
- CloudWatch dashboards
- Application Load Balancer target groups and listener rules

**Use when:** Deploying DSpace digital repository application.

## Current Applications

### DSpace Digital Repository
The first application deployed using these modules is DSpace 7+, an open-source repository platform for digital collections. The combination of `drcc-foundation`, `solr-search-cluster`, and `dspace-app-services` provides a complete, production-ready DSpace deployment.

### Future Applications
The modular design allows for deploying other DRCC applications using the foundation module with custom application modules. Examples might include:
- Custom web applications on ECS
- Data processing pipelines
- API services
- Other repository platforms

## Module Catalog

| Module | Purpose | Dependencies |
|--------|---------|--------------|
| [drcc-foundation](./modules/drcc-foundation/) |  | None |
| [dspace-app-services](./modules/dspace-app-services/) |  | drcc-foundation |
| [solr-search-cluster](./modules/solr-search-cluster/) |  | drcc-foundation |
## Getting Started

### Prerequisites

- Terraform or OpenTofu >= 1.0
- AWS CLI configured with appropriate credentials
- SSL certificate in AWS Certificate Manager (for HTTPS)
- Route53 hosted zone (optional, for custom domain)

### Quick Start

1. **Clone the repository:**
```bash
git clone https://github.com/jhu/terraform-aws-jhu-drcc.git
cd terraform-aws-jhu-drcc
```

2. **Choose an example configuration:**
```bash
cd examples/complete  # Full DSpace with Solr
# OR
cd examples/with-solr  # Foundation + Solr only
# OR
cd examples/foundation-only  # Infrastructure only
```

3. **Configure your deployment:**
```bash
cp stage.tfvars.example stage.tfvars
# Edit stage.tfvars with your values
```

4. **Deploy:**
```bash
terraform init
terraform plan -var-file=stage.tfvars
terraform apply -var-file=stage.tfvars
```

See the [examples](./examples/) directory for detailed configuration examples.

## Usage Examples

### Complete DSpace Deployment

```hcl
module "foundation" {
  source = "github.com/jhu/terraform-aws-jhu-drcc//modules/drcc-foundation?ref=v2.0.0"
  
  organization = "jhu"
  project_name = "dspace"
  environment  = "prod"
  aws_region   = "us-east-1"
  
  create_vpc           = true
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  deploy_database      = true
  db_instance_class    = "db.r5.xlarge"
  db_allocated_storage = 500
}

module "solr" {
  source = "github.com/jhu/terraform-aws-jhu-drcc//modules/solr-search-cluster?ref=v2.0.0"
  
  organization = "jhu"
  project_name = "dspace"
  environment  = "prod"
  aws_region   = "us-east-1"
  
  vpc_id                           = module.foundation.vpc_id
  private_subnet_ids               = module.foundation.private_subnet_ids
  ecs_cluster_id                   = module.foundation.ecs_cluster_id
  ecs_cluster_arn                  = module.foundation.ecs_cluster_arn
  ecs_cluster_name                 = module.foundation.ecs_cluster_name
  service_discovery_namespace_id   = module.foundation.service_discovery_namespace_id
  service_discovery_namespace_name = module.foundation.service_discovery_namespace_name
  
  solr_node_count  = 5
  deploy_zookeeper = true
}

module "dspace_app" {
  source = "github.com/jhu/terraform-aws-jhu-drcc//modules/dspace-app-services?ref=v2.0.0"
  
  organization = "jhu"
  project_name = "dspace"
  environment  = "prod"
  aws_region   = "us-east-1"
  
  vpc_id                   = module.foundation.vpc_id
  private_subnet_ids       = module.foundation.private_subnet_ids
  ecs_cluster_id           = module.foundation.ecs_cluster_id
  ecs_cluster_arn          = module.foundation.ecs_cluster_arn
  alb_https_listener_arn   = module.foundation.alb_https_listener_arn
  private_alb_listener_arn = module.foundation.private_alb_listener_arn
  
  dspace_angular_task_count = 4
  dspace_api_task_count     = 4
}
```

## Documentation

- [Architecture Analysis](./ARCHITECTURE_ANALYSIS.md) - Design decisions and module scoping
- [Migration Guide](./MIGRATION.md) - Upgrading from v1.x to v2.0
- [Production Deployment Guide](./examples/complete/PRODUCTION.md) - Best practices for production
- [Module Documentation](./modules/) - Detailed module documentation

## Versioning and Dependency Management

This module library follows semantic versioning (MAJOR.MINOR.PATCH):

- **Major version** - Breaking changes that are not backward-compatible
- **Minor version** - New features or enhancements that are backward-compatible
- **Patch version** - Bug fixes that are backward-compatible

### Version Constraints

```hcl
# Pin to specific version (recommended for production)
source = "github.com/jhu/terraform-aws-jhu-drcc//modules/drcc-foundation?ref=v2.0.0"

# Pin to minor version (get patches automatically)
source = "github.com/jhu/terraform-aws-jhu-drcc//modules/drcc-foundation?ref=v2.0"

# Use latest (not recommended for production)
source = "github.com/jhu/terraform-aws-jhu-drcc//modules/drcc-foundation"
```

## Migration from v1.x

If you're upgrading from the old module structure, see the [Migration Guide](./MIGRATION.md) for detailed instructions.

**Key changes in v2.0:**
- Module names updated (baseline-infrastructure → drcc-foundation, etc.)
- ECS cluster moved to foundation module
- Target groups moved to application modules
- Service discovery namespace moved to foundation module
- Improved module interfaces and separation of concerns

## Contribution Guidelines

We welcome contributions to this module library. If you have a new module or an improvement to an existing one:

1. Fork the repository
2. Create a new branch for your changes
3. Implement your changes and update documentation
4. Run `terraform fmt` to ensure consistent code formatting
5. Test your changes in a non-production environment
6. Submit a pull request with a detailed description

All pull requests will be reviewed by the infrastructure team before being merged.

## Cost Estimates

Typical monthly costs for production deployment:

| Component | Configuration | Estimated Cost |
|-----------|--------------|----------------|
| RDS (db.r5.xlarge Multi-AZ) | 4 vCPU, 32 GB RAM | ~$800 |
| ECS Fargate (Solr + DSpace) | 5 Solr + 8 DSpace tasks | ~$600-1200 |
| Application Load Balancers | 2 ALBs | ~$50 |
| NAT Gateways | 3 (one per AZ) | ~$100 |
| Data Transfer | Variable | ~$50-200 |
| **Total** | | **~$1,600-2,350/month** |

Use [AWS Pricing Calculator](https://calculator.aws) for detailed estimates based on your specific requirements.

## Support and Feedback

- **Slack:** #dev-ops channel in JHU Libraries Slack
- **Email:** devops@library.jhu.edu
- **Issues:** [GitHub Issues](https://github.com/jhu/terraform-aws-jhu-drcc/issues)

## License

[MIT License](./LICENSE)

## Acknowledgments

Developed and maintained by the JHU Libraries DevOps team for the Digital Research and Curation Center.

<!-- BEGIN_TF_DOCS -->


## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
