# DRCC Foundation Module

This module provides the foundational AWS infrastructure for DRCC applications, including VPC, load balancers, ECS cluster, RDS database, and supporting services.

## Features

- VPC with public and private subnets across multiple availability zones
- Application Load Balancers (public and private)
- ECS Fargate cluster for containerized applications
- RDS PostgreSQL database (optional)
- CloudMap service discovery namespace
- IAM roles for ECS tasks
- CloudWatch monitoring and alarms
- WAF web application firewall
- Route53 private hosted zone

## Architecture

The foundation module creates shared infrastructure that can be used by multiple application modules. It follows AWS best practices for high availability, security, and cost optimization.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

See the [examples](../../examples/) directory for complete usage examples:
- [Foundation Only](../../examples/foundation-only/) - Deploy just the foundation infrastructure
- [With Solr](../../examples/with-solr/) - Foundation + Solr search cluster
- [Complete](../../examples/complete/) - Full DSpace deployment

## Notes

- The ECS cluster is created but no services are deployed by this module
- Application modules should create their own target groups and listener rules
- The service discovery namespace is shared across all applications
- Database deployment is optional via the `deploy_database` variable
