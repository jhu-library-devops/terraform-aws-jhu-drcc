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
  
  # Initialization uses the DSpace-managed database secret automatically.
  enable_init_tasks                 = true
  dspace_admin_password_secret_arn = var.dspace_admin_password_secret_arn
  solr_url                          = "http://${module.foundation.private_alb_dns_name}:8983/solr"
  dspace_api_image                  = "dspace/dspace:7.6"
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

### Administrator credentials

Store a randomly generated administrator password of at least 12 characters as a plaintext Secrets Manager secret, grant the foundation ECS execution role access to its ARN, and pass that ARN through `dspace_admin_password_secret_arn`. Do not place the password in Terraform configuration, tfvars, commands, or logs.

### Solr Initialization
- Runs `dspace solr-import-collections`
- Creates required Solr collections
- Imports collection configurations
- Sets up search indexes

## Customization

### Custom administrator

Set the root-module inputs instead of editing module source:

```hcl
dspace_admin_email               = "repository-admin@example.edu"
dspace_admin_first_name          = "Repository"
dspace_admin_last_name           = "Administrator"
dspace_admin_password_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:dspace/prod/admin-password-example"
```

The secret value must be the password string itself, not a JSON object.

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

Confirm the secret exists without printing its value:

```bash
aws secretsmanager describe-secret \
  --secret-id <secret-arn> \
  --query '{ARN:ARN,Name:Name,LastChangedDate:LastChangedDate}'
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

1. **Protect administrator credentials**: inject the password from Secrets Manager and rotate it after first use
2. **Disable After Use**: Set `enable_init_tasks = false` after initialization
3. **Restrict Lambda Execution**: Use IAM policies to control who can invoke the Lambda function
4. **Audit Logs**: Review CloudWatch Logs for initialization activities

## Cost

Initialization tasks run on Fargate and incur minimal costs:
- Database init: ~2-5 minutes on 1 vCPU, 2 GB RAM
- Solr init: ~1-3 minutes on 0.5 vCPU, 1 GB RAM
- Lambda: Minimal cost for orchestration

Estimated cost per initialization: < $0.10
