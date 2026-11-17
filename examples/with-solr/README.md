# Foundation with Solr Search Cluster

This example composes `drcc-foundation` and `solr-search-cluster` without deploying DSpace application services or RDS.

## External database contract

The Solr module currently requires a reachable PostgreSQL endpoint and a Secrets Manager credentials ARN. Supply both as `db_endpoint` and `db_secret_arn`. The foundation execution role is granted read access only to that explicit secret ARN.

The database must be reachable from the new VPC on TCP 5432. This example explicitly enables foundation VPC egress on that port. If the database uses a security group, its ingress must allow the foundation ECS security group and that reciprocal rule must have one Terraform owner. Do not place secret values in tfvars; only the secret ARN belongs there.

## Usage

```bash
cp dev.tfvars.example dev.tfvars
# Replace the domain, AWS account ID, database endpoint, and secret ARN.

tofu init
tofu plan -var-file=dev.tfvars -out=dev.tfplan
tofu apply dev.tfplan
```

The sample defaults to a low-cost single Solr node without Zookeeper. For production, use at least three Solr nodes, deploy a three- or five-node Zookeeper ensemble, select reviewed immutable image tags, and review EFS, alarms, and recovery procedures.

## Access

Solr is exposed internally through the private ALB at `http://<private_alb_dns_name>:8983/solr` and through Cloud Map node names. It is not directly exposed to the internet.

To deploy the full application stack, use [`../dspace-complete`](../dspace-complete/).
