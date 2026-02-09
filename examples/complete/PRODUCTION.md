# Production Deployment Guide

This guide provides recommendations and best practices for deploying DSpace to production using the DRCC Terraform modules.

## Pre-Deployment Checklist

### AWS Account Setup
- [ ] Dedicated AWS account or isolated VPC for production
- [ ] AWS Organizations SCPs applied for security guardrails
- [ ] CloudTrail enabled for audit logging
- [ ] AWS Config enabled for compliance monitoring
- [ ] Backup policies configured

### DNS and Certificates
- [ ] Route53 hosted zone created for your domain
- [ ] SSL/TLS certificate requested in AWS Certificate Manager (ACM)
- [ ] Certificate validated (DNS or email validation)
- [ ] Domain ownership verified

### Secrets Management
- [ ] Database credentials strategy defined
- [ ] Application secrets stored in AWS Secrets Manager
- [ ] IAM policies configured for secret access
- [ ] Secret rotation policies established

### Networking
- [ ] VPC CIDR blocks planned (avoid conflicts with on-prem networks)
- [ ] Subnet sizing calculated based on expected resource count
- [ ] VPN or Direct Connect configured (if needed)
- [ ] Network ACLs and security group rules reviewed

### Monitoring and Alerting
- [ ] SNS topics created for alarm notifications
- [ ] Email subscriptions configured
- [ ] PagerDuty/Slack integrations set up (optional)
- [ ] CloudWatch Log Groups retention policies defined

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

**Multi-AZ Deployment:**
- RDS Multi-AZ enabled
- ECS tasks distributed across 3 availability zones
- NAT Gateways in each AZ (already configured)
- ALB spans all AZs

**Disaster Recovery:**
- RDS automated backups (daily snapshots)
- EFS automatic backups enabled
- Cross-region replication for critical data (optional)
- Document recovery procedures

### Security Hardening

**Network Security:**
- All application components in private subnets
- ALB in public subnets only
- Security groups follow least-privilege principle
- WAF rules enabled (already configured)

**IAM Security:**
- Use IAM roles, never access keys in code
- Enable MFA for human users
- Implement least-privilege policies
- Regular access reviews

**Data Encryption:**
- RDS encryption at rest enabled
- EFS encryption enabled
- Secrets Manager for sensitive data
- TLS 1.2+ for all connections

**Additional Hardening:**
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

2. **Initialize Terraform:**
```bash
terraform init
```

3. **Review the plan:**
```bash
terraform plan -var-file=prod.tfvars -out=prod.tfplan
# Review all resources carefully
```

4. **Apply in stages (recommended):**
```bash
# Stage 1: Foundation only
terraform apply -target=module.foundation -var-file=prod.tfvars

# Stage 2: Solr cluster
terraform apply -target=module.solr -var-file=prod.tfvars

# Stage 3: Application services
terraform apply -target=module.dspace_app -var-file=prod.tfvars
```

5. **Verify deployment:**
```bash
# Check ECS services
aws ecs list-services --cluster <cluster-name>

# Check RDS status
aws rds describe-db-instances --db-instance-identifier <db-id>

# Check ALB health
aws elbv2 describe-target-health --target-group-arn <tg-arn>
```

### Post-Deployment

1. **Configure DNS:**
   - Create Route53 A record pointing to ALB
   - Verify SSL certificate is working
   - Test public access

2. **Initialize DSpace:**
   - Run database migrations
   - Create admin user
   - Configure DSpace settings

3. **Configure monitoring:**
   - Verify CloudWatch alarms are active
   - Test alarm notifications
   - Set up dashboards

4. **Load testing:**
   - Perform load testing before go-live
   - Adjust task counts based on results
   - Document performance baselines

## Ongoing Operations

### Monitoring

**Key Metrics:**
- ECS CPU/Memory utilization (target: <70%)
- RDS CPU/Memory/IOPS (target: <80%)
- ALB request count and latency
- Solr query performance
- EFS throughput and IOPS

**CloudWatch Dashboards:**
- Infrastructure overview (ALB, ECS, RDS)
- Application performance (response times, errors)
- Solr cluster health
- Cost tracking

### Maintenance Windows

**Recommended schedule:**
- Database maintenance: Sunday 2-4 AM
- Application updates: Rolling deployments (no downtime)
- Infrastructure changes: Planned maintenance windows

**Update process:**
```bash
# Update task definitions
terraform apply -var-file=prod.tfvars

# Force new deployment
aws ecs update-service --cluster <cluster> --service <service> --force-new-deployment
```

### Backup and Recovery

**Automated backups:**
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
# Update prod.tfvars
db_instance_class = "db.r5.2xlarge"
solr_cpu          = "8192"
solr_memory       = "16384"

# Apply changes
terraform apply -var-file=prod.tfvars
```

**Horizontal scaling (add instances):**
```hcl
# Update prod.tfvars
solr_node_count           = 7
dspace_angular_task_count = 6
dspace_api_task_count     = 6

# Apply changes
terraform apply -var-file=prod.tfvars
```

## Cost Optimization

**Production cost estimates (monthly):**
- RDS db.r5.xlarge Multi-AZ: ~$800
- ECS Fargate tasks (Solr + DSpace): ~$600-1200
- ALB: ~$50
- NAT Gateways (3): ~$100
- Data transfer: Variable
- **Total: ~$1,550-2,150/month**

**Cost reduction strategies:**
- Use Savings Plans or Reserved Instances (30-50% savings)
- Right-size resources based on actual usage
- Enable S3 lifecycle policies for old backups
- Use CloudWatch Logs retention policies
- Consider Aurora Serverless for variable workloads

## Troubleshooting

**Common issues:**

1. **ECS tasks failing to start:**
   - Check CloudWatch Logs for task errors
   - Verify IAM role permissions
   - Check security group rules

2. **Database connection failures:**
   - Verify security group allows ECS → RDS
   - Check Secrets Manager secret format
   - Verify RDS is in available state

3. **ALB health checks failing:**
   - Check target group health check settings
   - Verify application is listening on correct port
   - Review security group rules

4. **High costs:**
   - Review CloudWatch metrics for over-provisioning
   - Check for idle resources
   - Enable AWS Cost Explorer

## Support and Escalation

**Internal support:**
- Slack: #dev-ops channel
- Email: devops@library.jhu.edu

**AWS support:**
- AWS Support Console (Business/Enterprise plan)
- TAM (Technical Account Manager) if available

**Emergency contacts:**
- On-call engineer: [PagerDuty/phone]
- Infrastructure lead: [contact info]
- AWS account owner: [contact info]
