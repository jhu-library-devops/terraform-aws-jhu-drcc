# JHU DRCC Terraform Modules

Terraform modules for deploying JHU Digital Research and Curation Center (DRCC) infrastructure on AWS.

## Overview

This repository provides reusable Terraform modules for deploying cloud infrastructure on AWS. While initially developed for DSpace 7+ deployments, the modules are designed to be flexible and reusable for other DRCC applications and services.

The modules follow AWS best practices for high availability, monitoring, security, and cost optimization.

## Module Philosophy

This module library separates infrastructure into three layers:

1. **Separation of Concerns** - The foundation module provides shared infrastructure (VPC, ECS cluster, load balancers), while application modules manage their own resources.
2. **Reusability** - Modules are designed to be composed for different applications, not just DSpace.
3. **Operational Requirements** - Modules include monitoring, security configurations, and high availability patterns needed for production deployments.

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
The first application deployed using these modules is [DSpace 7+](https://github.com/jhu-sheridan-libraries/DSpace), an open-source repository platform for digital collections. The combination of `drcc-foundation`, `solr-search-cluster`, and `dspace-app-services` provides a complete, production-ready DSpace deployment.

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

1. **Reference modules in your Terraform configuration:**

```hcl
module "foundation" {
  source = "github.com/jhu/terraform-aws-jhu-drcc//modules/drcc-foundation?ref=v2.0.0"
  
  organization = "your-org"
  project_name = "your-project"
  environment  = "prod"
  aws_region   = "us-east-1"
  
  create_vpc           = true
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}
```

2. **Initialize and deploy:**
```bash
tofu init
tofu plan
tofu apply
```

See the [examples](./examples/) directory for complete configuration examples including DSpace and Solr deployments.

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
- [Refactoring Summary](./REFACTORING_SUMMARY.md) - Details of v2.0 refactoring changes
- [Production Deployment Guide](./examples/complete/PRODUCTION.md) - Best practices for production
- [DSpace Initialization Guide](./examples/complete/INITIALIZATION.md) - Setting up DSpace after deployment
- [Module Documentation](./modules/) - Detailed module documentation
- [Examples](./examples/) - Complete configuration examples

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

## Adding a New Module

1. **Plan your module:**
   - Determine if it should depend on `drcc-foundation` or be standalone
   - Define clear input variables and outputs
   - Follow the separation of concerns principle

2. **Create module structure:**
   ```
   modules/your-module-name/
   ├── main.tf           # Primary resource definitions
   ├── variables.tf      # Input variable declarations
   ├── outputs.tf        # Output value declarations
   ├── versions.tf       # Terraform and provider version constraints
   └── README.md         # Module documentation
   ```

3. **Implement the module:**
   - Use consistent naming: `${var.organization}-${var.project_name}-${var.environment}-resource-name`
   - Add appropriate tags to all resources
   - Include CloudWatch monitoring and alarms where applicable
   - Follow AWS best practices for security and high availability

4. **Document the module:**
   - Create a comprehensive README.md with:
     - Purpose and use cases
     - Architecture diagram (if complex)
     - Usage examples
     - Input/output documentation (use terraform-docs)
   - Add inline comments for complex logic

5. **Generate documentation:**
   ```bash
   cd modules/your-module-name
   terraform-docs markdown table --output-file README.md --output-mode inject .
   ```

6. **Update repository documentation:**
   - Add module to the Module Catalog table in root README.md
   - Create an example in `examples/` directory if applicable
   - Update CHANGELOG.md with your changes

## Contributing Changes

Thank you for your interest in contributing to our project. The module library accepts contributions from JHU DRCC staff and faculty. We are currently not accepting outside contributions to this project.

## Support and Feedback

- **Slack:** #dev-ops channel in JHU Libraries Slack
- **Email:** devops@library.jhu.edu
- **Issues:** [GitHub Issues](https://github.com/jhu/terraform-aws-jhu-drcc/issues)

### Reporting Bugs/Feature Requests

We welcome you to use the GitHub issue tracker to report bugs or suggest features.

When filing an issue, please check existing open, or recently closed, issues to make sure somebody else hasn't already reported the issue. Please try to include as much information as you can. Details like these are incredibly useful:

A reproducible test case or series of steps
The version of our code being used
Any modifications you've made relevant to the bug
Anything unusual about your environment or deployment

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