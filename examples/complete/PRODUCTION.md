# Production Deployment Guide

This guide covers deploying DSpace to production using the DRCC Terraform modules.

## Pre-Deployment Checklist

### DNS and Certificates
- [ ] Route53 hosted zone created for your domain
- [ ] SSL/TLS certificate requested in ACM and validated
- [ ] Domain ownership verified

### Secrets Management
- [ ] Database credentials stored in AWS Secrets Manager
- [ ] Secret rotation policies established for DSpace DB credentials

### Networking
- [ ] VPC CIDR blocks planned (avoid conflicts with on-prem/campus networks)
- [ ] VPN or Direct Connect configured for campus network access (if needed)

## Production Configuration

### Compute Resources

**Database (RDS PostgreSQL):**
```hcl
db_instance_class    = "db.r5.xlarge"    # 4 vCPU, 32 GB RAM
db_allocated_storage = 500                # Start with 500 GB
db_multi_az          = true               # High availability
```

Consider:
- `db.r5.2xlarge` for larger repositories (>1M items)
- Enable automated backups with 7-30 day retention
- Enable Performance Insights for query monitoring

**Solr Cluster:**
```hcl
solr_node_count      = 5      # Odd number for quorum
deploy_zookeeper     = true
zookeeper_task_count = 3      # Always use 3 or 5 for production
solr_cpu             = "4096" # 4 vCPU
solr_memory          = "8192" # 8 GB RAM
```

Sizing guidelines:
- 1-2 nodes: Development only
- 3 nodes: Small production (<100K items)
- 5 nodes: Medium production (100K-1M items)
- 7+ nodes: Large production (>1M items)

**DSpace Application:**
```hcl
dspace_angular_task_count = 4  # Scale based on traffic
dspace_api_task_count     = 4  # Scale based on API load
```

Consider:
- Enable auto-scaling based on CPU/memory metrics
- Set minimum 2 tasks per service for high availability
- Monitor request latency and adjust task counts

### High Availability

- RDS Multi-AZ enabled
- ECS tasks distributed across 3 availability zones
- NAT Gateways in each AZ (already configured)
- ALB spans all AZs

### Security Hardening

```hcl
# In drcc-foundation module
enable_waf                = true
enable_deletion_protection = true  # For RDS and ALB
enable_backup_retention   = 30     # Days
```

## Deployment Process

### Initial Deployment

1. **Prepare configuration:**
```bash
cd examples/complete
cp prod.tfvars.example prod.tfvars
# Edit prod.tfvars with your values
```

2. **Initialize and plan:**
```bash
terraform init
terraform plan -var-file=prod.tfvars -out=prod.tfplan
```

3. **Apply in stages (recommended):**
```bash
# Stage 1: Foundation only
terraform apply -target=module.foundation -var-file=prod.tfvars

# Stage 2: Solr cluster
terraform apply -target=module.solr -var-file=prod.tfvars

# Stage 3: Application services
terraform apply -target=module.dspace_app -var-file=prod.tfvars
```

4. **Verify deployment:**
```bash
aws ecs list-services --cluster <cluster-name>
aws rds describe-db-instances --db-instance-identifier <db-id>
aws elbv2 describe-target-health --target-group-arn <tg-arn>
```

### Post-Deployment

1. **Configure DNS:** Create Route53 A record pointing to ALB, verify SSL
2. **Initialize DSpace:** Run database migrations, create admin user, configure DSpace settings
3. **Load testing:** Perform load testing before go-live, adjust task counts based on results

## Ongoing Operations

### Key Metrics
- ECS CPU/Memory utilization (target: <70%)
- RDS CPU/Memory/IOPS (target: <80%)
- ALB request count and latency
- Solr query performance
- EFS throughput and IOPS

### Maintenance

- Database maintenance: Sunday 2-4 AM
- Application updates: Rolling deployments (no downtime)

**Update process:**
```bash
terraform apply -var-file=prod.tfvars

# Force new deployment if needed
aws ecs update-service --cluster <cluster> --service <service> --force-new-deployment
```

### Backup and Recovery

- RDS: Daily snapshots, 30-day retention
- EFS: AWS Backup daily, 30-day retention
- Terraform state: S3 versioning enabled

**Recovery procedures:**
1. Database restore from RDS snapshot
2. EFS restore from backup vault
3. Redeploy infrastructure from Terraform state

### Scaling

**Vertical scaling (increase resources):**
```hcl
db_instance_class = "db.r5.2xlarge"
solr_cpu          = "8192"
solr_memory       = "16384"
```

**Horizontal scaling (add instances):**
```hcl
solr_node_count           = 7
dspace_angular_task_count = 6
dspace_api_task_count     = 6
```

## Cost Estimates (monthly)

- RDS db.r5.xlarge Multi-AZ: ~$800
- ECS Fargate tasks (Solr + DSpace): ~$600-1200
- ALB: ~$50
- NAT Gateways (3): ~$100
- Data transfer: Variable
- **Total: ~$1,550-2,150/month**

## Troubleshooting

1. **ECS tasks failing to start:** Check CloudWatch Logs for task errors, verify security group rules
2. **Database connection failures:** Verify security group allows ECS → RDS, check Secrets Manager secret format
3. **ALB health checks failing:** Check target group health check settings, verify DSpace is listening on correct port

## Support

- Slack: #dev-ops channel
- Email: devops@library.jhu.edu
- On-call engineer: [PagerDuty/phone]
- Infrastructure lead: [contact info]
