# DSpace App Services Module

This module deploys the DSpace 7+ application services including the Angular UI, REST API, and background jobs on ECS Fargate.

## Features

- DSpace Angular UI service (frontend)
- DSpace REST API service (backend)
- DSpace background jobs service (cron tasks)
- S3 buckets for asset storage and statistics
- EventBridge scheduled tasks for maintenance
- GitHub Actions OIDC integration for CI/CD
- CloudWatch dashboards for application monitoring
- Application Load Balancer target groups and listener rules

## Architecture

The DSpace application is deployed as three separate ECS services:
1. **Angular UI** - Serves the frontend application
2. **REST API** - Provides the backend API
3. **Background Jobs** - Runs scheduled maintenance tasks

All services share the same ECS cluster and can scale independently.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

See the [examples](../../examples/) directory for complete usage examples:
- [Complete](../../examples/complete/) - Full DSpace deployment

## Task Definitions

This module supports two modes for task definitions:

### 1. External Task Definitions (Recommended for CI/CD)
Manage task definitions separately (e.g., via GitHub Actions) and provide the ARNs:

```hcl
dspace_angular_task_def_arn = "arn:aws:ecs:us-east-1:123456789012:task-definition/dspace-angular:5"
dspace_api_task_def_arn     = "arn:aws:ecs:us-east-1:123456789012:task-definition/dspace-api:5"
dspace_jobs_task_def_arn    = "arn:aws:ecs:us-east-1:123456789012:task-definition/dspace-jobs:5"
```

### 2. Module-Managed Task Definitions
Let the module create basic task definitions (useful for initial setup).

## Scaling

Configure the number of tasks for each service:

```hcl
dspace_angular_task_count = 4  # Frontend instances
dspace_api_task_count     = 4  # Backend instances
```

Consider using ECS auto-scaling for production workloads.

## Notes

- Requires the `drcc-foundation` module to be deployed first
- S3 buckets are created for asset storage and statistics exports
- EventBridge rules can be configured for scheduled maintenance tasks
- GitHub Actions OIDC allows secure deployments without long-lived credentials
