# Complete DSpace Deployment Example

This example demonstrates a complete DSpace deployment using all three modules:
- `drcc-foundation` - Core infrastructure (VPC, ALB, RDS, IAM)
- `solr-search-cluster` - Solr search with Zookeeper
- `dspace-app-services` - DSpace Angular UI, REST API, and background jobs

## Architecture

![AWS Architecture Diagram](https://lucid.app/publicSegments/view/901491ef-aa95-4759-a4d8-367bfd071b23/image.png)

This configuration deploys:
- VPC with public and private subnets across 3 availability zones
- Application Load Balancer (public and private)
- RDS PostgreSQL database
- ECS cluster with Fargate tasks
- Solr cluster (3 nodes) with Zookeeper (3 nodes)
- DSpace Angular UI and REST API services
- CloudWatch monitoring and alarms
- WAF for web application firewall

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform or OpenTofu >= 1.0
- Route53 hosted zone for your domain (if using custom domain)
- SSL certificate in ACM (if using HTTPS)

## Usage

1. Copy the example tfvars file:
```bash
cp stage.tfvars.example stage.tfvars
```

2. Edit `stage.tfvars` with your values:
   - Update `public_domain` to your actual domain
   - Adjust CIDR blocks if needed
   - Configure database and compute resources

3. Initialize Terraform:
```bash
terraform init
```

4. Review the plan:
```bash
terraform plan -var-file=stage.tfvars
```

5. Apply the configuration:
```bash
terraform apply -var-file=stage.tfvars
```

## Customization

### Using Existing VPC
Set `create_vpc = false` in the foundation module and provide:
- `vpc_id`
- `public_subnet_ids`
- `private_subnet_ids`

### Using Existing Database
Set `deploy_database = false` and provide:
- `db_instance_identifier`
- `db_credentials_secret_arn_override`

### External Task Definitions
If you manage ECS task definitions separately (e.g., via CI/CD), uncomment and set:
- `dspace_angular_task_def_arn`
- `dspace_api_task_def_arn`
- `dspace_jobs_task_def_arn`

## Outputs

After deployment, Terraform will output:
- ALB DNS names
- Database endpoint
- ECS cluster information
- Security group IDs

## Cost Considerations

This example deploys:
- RDS db.t3.medium instance
- Multiple Fargate tasks (Solr, Zookeeper, DSpace services)
- Application Load Balancers
- NAT Gateways (3 for high availability)

For development/testing, consider:
- Reducing `solr_node_count` to 1
- Setting `deploy_zookeeper = false` (use embedded Zookeeper)
- Using smaller instance types
- Reducing task counts
