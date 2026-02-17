# DSpace Initialization Guide

This guide explains how to use the ECS task-based initialization feature to set up your DSpace deployment.

## Overview

The dspace-app-services module includes an optional initialization system that:
1. Runs database migrations and creates the initial admin user
2. Imports Solr collections and configures search indexes

This is implemented using:
- ECS Fargate tasks for running initialization commands
- Lambda function to orchestrate the tasks sequentially
- CloudWatch Logs for monitoring progress

## When to Use

Enable initialization tasks when:
- Deploying DSpace for the first time
- Upgrading DSpace versions that require database migrations
- Resetting or rebuilding Solr indexes

## Configuration

### 1. Enable Initialization in Terraform

```hcl
module "dspace_app" {
  source = "../../modules/dspace-app-services"
  
  # ... other configuration ...
  
  # Enable initialization
  enable_init_tasks = true
  db_secret_arn     = module.foundation.db_credentials_secret_arn
  solr_url          = "http://${module.foundation.private_alb_dns_name}:8983/solr"
  dspace_api_image  = "dspace/dspace:7.6"
}
```

### 2. Deploy Infrastructure

```bash
terraform apply -var-file=prod.tfvars
```

This creates:
- Database initialization task definition
- Solr initialization task definition
- Lambda function to run the tasks
- CloudWatch log group for initialization logs

### 3. Run Initialization

Invoke the Lambda function to start initialization:

```bash
aws lambda invoke \
  --function-name jhu-prod-dspace-init-tasks \
  --region us-east-1 \
  response.json

cat response.json
```

### 4. Monitor Progress

Check CloudWatch Logs:

```bash
# View database initialization logs
aws logs tail /ecs/prod-dspace-init --follow --filter-pattern "db-init"

# View Solr initialization logs
aws logs tail /ecs/prod-dspace-init --follow --filter-pattern "solr-init"
```

### 5. Disable After Completion

Once initialization is complete, disable it to avoid accidental re-runs:

```hcl
enable_init_tasks = false
```

```bash
terraform apply -var-file=prod.tfvars
```

## What Gets Initialized

### Database Initialization
- Runs `dspace database migrate` to create/update schema
- Creates initial admin user with credentials:
  - Email: `admin@example.com`
  - Password: `admin`
  - **⚠️ Change these immediately after first login!**

### Solr Initialization
- Runs `dspace solr-import-collections`
- Creates required Solr collections
- Imports collection configurations
- Sets up search indexes

## Customization

### Custom Admin User

To customize the admin user, modify the initialization task definition:

```hcl
# In initialization.tf
command = [
  "/bin/bash",
  "-c",
  "dspace database migrate && dspace create-administrator -e your-email@example.com -f FirstName -l LastName -p YourPassword -c en"
]
```

### Additional Initialization Steps

Add more commands to the initialization tasks:

```hcl
command = [
  "/bin/bash",
  "-c",
  <<-EOT
    dspace database migrate
    dspace create-administrator -e admin@example.com -f Admin -l User -p admin -c en
    dspace index-discovery -b
    dspace oai import -c
  EOT
]
```

## Troubleshooting

### Task Fails to Start

Check:
- ECS cluster has capacity
- Security groups allow outbound traffic
- IAM roles have correct permissions

```bash
aws ecs describe-tasks \
  --cluster jhu-prod-dspace-cluster \
  --tasks <task-arn>
```

### Database Connection Errors

Verify:
- Database is accessible from ECS tasks
- Security group allows traffic on port 5432
- Database credentials in Secrets Manager are correct

```bash
aws secretsmanager get-secret-value \
  --secret-id <secret-arn> \
  --query SecretString \
  --output text | jq
```

### Solr Connection Errors

Check:
- Solr cluster is running and healthy
- Private ALB is accessible from ECS tasks
- Solr URL is correct

```bash
# Test Solr connectivity
curl http://<private-alb-dns>:8983/solr/admin/cores?action=STATUS
```

### Lambda Timeout

If initialization takes longer than 15 minutes:
- Check CloudWatch Logs for the specific failure
- Consider running tasks manually via ECS console
- Increase Lambda timeout if needed (max 15 minutes)

## Manual Initialization

If you prefer to run initialization manually:

### 1. Run Database Migration

```bash
aws ecs run-task \
  --cluster jhu-prod-dspace-cluster \
  --task-definition jhu-prod-dspace-db-init \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=DISABLED}"
```

### 2. Run Solr Import

```bash
aws ecs run-task \
  --cluster jhu-prod-dspace-cluster \
  --task-definition jhu-prod-dspace-solr-init \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=DISABLED}"
```

## Security Considerations

1. **Change Default Admin Password**: The default admin credentials should be changed immediately
2. **Disable After Use**: Set `enable_init_tasks = false` after initialization
3. **Restrict Lambda Execution**: Use IAM policies to control who can invoke the Lambda function
4. **Audit Logs**: Review CloudWatch Logs for initialization activities

## Cost

Initialization tasks run on Fargate and incur minimal costs:
- Database init: ~2-5 minutes on 1 vCPU, 2 GB RAM
- Solr init: ~1-3 minutes on 0.5 vCPU, 1 GB RAM
- Lambda: Minimal cost for orchestration

Estimated cost per initialization: < $0.10
