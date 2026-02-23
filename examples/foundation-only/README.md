# Foundation Only Example

Deploy the `drcc-foundation` module on its own — without Solr, DSpace, or any application services. This is the recommended starting point for any institution adopting these modules.

## What Gets Created

- VPC with public and private subnets (or bring your own)
- Public and private Application Load Balancers
- ECS Fargate cluster
- RDS PostgreSQL database (optional)
- IAM roles for ECS tasks
- CloudMap service discovery namespace
- Route53 private hosted zone
- WAF web application firewall
- CloudWatch monitoring and SNS alarms

## Adapting This for Your Institution

The module was built at JHU but is designed to be reused. Here's what to change.

### 1. Set your identity variables

Every resource is tagged and named using `organization`, `project_name`, and `environment`. Replace the JHU defaults with your own:

```hcl
module "foundation" {
  source = "github.com/jhu/terraform-aws-jhu-drcc//modules/drcc-foundation?ref=v2.0.0"

  organization = "mit"           # your institution's short name
  project_name = "repository"    # your project name
  environment  = "prod"
  aws_region   = "us-west-2"    # your preferred region
}
```

### 2. Configure networking

You can either create a new VPC or plug into an existing one.

**Create a new VPC** (default):

```hcl
  create_vpc           = true
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
```

**Use an existing VPC** (common in enterprise environments):

```hcl
  create_vpc         = false
  vpc_id             = "vpc-0abc123def456"
  public_subnet_ids  = ["subnet-aaa", "subnet-bbb"]
  private_subnet_ids = ["subnet-ccc", "subnet-ddd"]
```

### 3. Configure the database

The module can create a managed RDS PostgreSQL instance or skip it entirely if you manage databases separately.

**Create a new database:**

```hcl
  deploy_database      = true
  db_instance_class    = "db.r5.large"    # size for your workload
  db_allocated_storage = 100
  db_name              = "dspace"
  db_username          = "appuser"
  db_multi_az          = true             # recommended for production
```

**Use an existing database:**

```hcl
  deploy_database                  = false
  db_instance_identifier           = "my-existing-rds-instance"
  db_credentials_secret_arn_override = "arn:aws:secretsmanager:us-east-1:123456789:secret:my-db-creds"
```

### 4. Set up your domain and SSL

```hcl
  public_domain          = "repository.example.edu"
  create_ssl_certificate = true    # creates an ACM cert (requires DNS validation)

  # OR bring your own certificate:
  # create_ssl_certificate = false
  # ssl_certificate_arn    = "arn:aws:acm:us-east-1:123456789:certificate/abc-123"
```

If you have a Route53 hosted zone, the module can create a DNS alias automatically:

```hcl
  public_hosted_zone_id = "Z0123456789ABCDEF"
```

### 5. Configure WAF and security

```hcl
  # Create a trusted IP set for admin access
  create_trusted_ip_set = true
  trusted_ip_addresses  = ["203.0.113.0/24"]   # your campus CIDR

  # OR reference an existing WAF IP set:
  # create_trusted_ip_set = false
  # trusted_ip_set_arn    = "arn:aws:wafv2:us-east-1:123456789:regional/ipset/my-ips/abc123"
```

### 6. Enable monitoring

```hcl
  enable_enhanced_monitoring = true
  alarm_notification_email   = "ops-team@example.edu"
```

## Quick Start

```bash
# Clone and navigate to this example
git clone https://github.com/jhu/terraform-aws-jhu-drcc.git
cd terraform-aws-jhu-drcc/examples/foundation-only

# Copy and edit the example tfvars
cp dev.tfvars.example myorg.tfvars
# Edit myorg.tfvars — at minimum set organization, project_name, and environment

# Deploy
tofu init    # or: terraform init
tofu plan  -var-file=myorg.tfvars
tofu apply -var-file=myorg.tfvars
```

## Using a tfvars File

A minimal configuration for another institution:

```hcl
# myorg.tfvars
organization = "mit"
project_name = "repository"
environment  = "dev"
aws_region   = "us-east-1"

vpc_cidr             = "10.5.0.0/16"
public_subnet_cidrs  = ["10.5.1.0/24", "10.5.2.0/24"]
private_subnet_cidrs = ["10.5.11.0/24", "10.5.12.0/24"]

db_instance_class    = "db.t3.small"
db_allocated_storage = 50
```

## Remote State (Recommended)

For team use, store state in S3 with locking. Add a `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "myorg-terraform-state"
    key            = "foundation/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
```

## Outputs

After deploying, the module exports everything downstream modules need:

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC ID |
| `private_subnet_ids` | Private subnet IDs for ECS tasks |
| `public_subnet_ids` | Public subnet IDs for load balancers |
| `ecs_cluster_id` / `ecs_cluster_arn` | ECS cluster identifiers |
| `alb_dns_name` | Public ALB DNS name |
| `alb_https_listener_arn` | HTTPS listener for adding app rules |
| `private_alb_listener_arn` | Private ALB listener for internal services |
| `db_instance_endpoint` | RDS connection endpoint |
| `db_credentials_secret_arn` | Secrets Manager ARN for DB credentials |
| `ecs_task_execution_role_arn` | IAM role for ECS task execution |
| `ecs_task_role_arn` | IAM role for ECS tasks |
| `service_discovery_namespace_id` | CloudMap namespace for service discovery |
| `sns_topic_arn` | SNS topic for alarm notifications |

Pass these into the `solr-search-cluster` or `dspace-app-services` modules when you're ready to add applications.

## Next Steps

1. Deploy a Solr cluster → see the [`with-solr`](../with-solr/) example
2. Deploy the full DSpace stack → see the [`complete`](../complete/) example
3. Harden for production → see the [Production Deployment Guide](../complete/PRODUCTION.md)
