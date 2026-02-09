# Solr Search Cluster Module

This module deploys a highly available Apache Solr search cluster on ECS Fargate with optional Zookeeper ensemble for coordination.

## Features

- Multi-node Solr cluster with configurable node count
- Optional Zookeeper ensemble (3 or 5 nodes recommended)
- EFS volumes for persistent data storage
- CloudWatch monitoring and health checks
- CloudWatch Synthetics canaries for availability monitoring
- Service discovery via CloudMap
- Auto-scaling support
- ECR repositories for container images

## Architecture

The Solr cluster uses ECS Fargate for compute, EFS for persistent storage, and CloudMap for service discovery. Each Solr node has a unique DNS name for direct access, and the cluster is accessible via a private Application Load Balancer.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

See the [examples](../../examples/) directory for complete usage examples:
- [With Solr](../../examples/with-solr/) - Foundation + Solr cluster
- [Complete](../../examples/complete/) - Full DSpace deployment with Solr

## Configuration Recommendations

### Development
```hcl
solr_node_count      = 1
deploy_zookeeper     = false  # Use embedded Zookeeper
solr_cpu             = "1024"
solr_memory          = "2048"
```

### Production
```hcl
solr_node_count      = 5      # Odd number for quorum
deploy_zookeeper     = true
zookeeper_task_count = 3      # 3 or 5 recommended
solr_cpu             = "4096"
solr_memory          = "8192"
```

## Notes

- Requires the `drcc-foundation` module to be deployed first
- Solr nodes are numbered starting from 1 (solr-1, solr-2, etc.)
- Zookeeper nodes are also numbered starting from 1
- EFS volumes are encrypted at rest and in transit
- Health checks monitor both Solr and Zookeeper availability
