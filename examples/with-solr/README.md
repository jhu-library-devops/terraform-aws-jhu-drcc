# Foundation with Solr Search Cluster

This example deploys the DRCC foundation infrastructure along with a Solr search cluster.

## What's Included

**Foundation Infrastructure:**
- VPC with public and private subnets
- Application Load Balancers
- RDS PostgreSQL database
- IAM roles and security groups
- CloudWatch monitoring

**Solr Search Cluster:**
- ECS cluster with Fargate
- Solr nodes (configurable count)
- Zookeeper ensemble (optional)
- EFS for persistent storage
- CloudWatch alarms and health checks
- Service discovery via CloudMap

## Architecture

The Solr cluster is deployed on ECS Fargate with:
- Individual Solr nodes with DNS-based identities
- Zookeeper ensemble for cluster coordination
- EFS volumes for data persistence
- Private ALB for internal access
- CloudWatch Synthetics canaries for health monitoring

## Usage

```bash
# Initialize
terraform init

# Plan with default 3-node cluster
terraform plan -var="environment=dev"

# Deploy
terraform apply -var="environment=dev"

# Deploy with custom configuration
terraform apply \
  -var="environment=prod" \
  -var="solr_node_count=5" \
  -var="solr_cpu=2048" \
  -var="solr_memory=4096"
```

## Configuration Options

### Minimal (Development)
```hcl
solr_node_count      = 1
deploy_zookeeper     = false  # Use embedded Zookeeper
solr_cpu             = "1024"
solr_memory          = "2048"
```

### Production
```hcl
solr_node_count      = 5
deploy_zookeeper     = true
zookeeper_task_count = 3
solr_cpu             = "4096"
solr_memory          = "8192"
db_instance_class    = "db.r5.large"
```

## Accessing Solr

Solr is accessible via the private ALB:
- Internal URL: `http://<private_alb_dns_name>:8983/solr`
- Service discovery: `solr-1.dspace.local`, `solr-2.dspace.local`, etc.

## Next Steps

After deploying, you can:
1. Add DSpace application services using the `complete` example
2. Configure Solr collections and schemas
3. Set up backup and restore procedures
4. Configure auto-scaling policies

## Cost Optimization

For non-production environments:
- Set `solr_node_count = 1`
- Set `deploy_zookeeper = false`
- Use smaller CPU/memory allocations
- Consider using Spot instances (requires custom task definition)
