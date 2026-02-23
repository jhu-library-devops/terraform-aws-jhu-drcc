# Getting Started with the JHU DRCC Terraform Modules

A introduction to deploying DSpace on AWS using the DRCC Terraform module library.

---

## What Is This?

This repository contains reusable infrastructure-as-code (IaC) modules that deploy a complete [DSpace](https://dspace.lyrasis.org/) digital repository on AWS.

The stack is composed of three modules that layer on top of each other:

| Module | What It Creates | Depends On |
|--------|----------------|------------|
| [drcc-foundation](../modules/drcc-foundation/) | VPC, load balancers, ECS cluster, RDS database, WAF, IAM roles | Nothing |
| [solr-search-cluster](../modules/solr-search-cluster/) | Multi-node Solr cluster with Zookeeper on ECS + EFS | drcc-foundation |
| [dspace-app-services](../modules/dspace-app-services/) | DSpace Angular UI, REST API, background jobs, S3 storage | solr-search-cluster | drcc-foundation |

You can deploy them incrementally — foundation first, then add Solr, then add DSpace — or all at once.

---

## Prerequisites

Before you begin, make sure you have the following:

### Tools

- **OpenTofu >= 1.6** or **Terraform >= 1.0** — OpenTofu is the open-source fork and what this project recommends. Install it from [opentofu.org](https://opentofu.org/docs/intro/install/).
- **AWS CLI v2** — Install from [aws.amazon.com/cli](https://aws.amazon.com/cli/). Run `aws --version` to confirm.
- **Git** — To clone this repository.

### AWS Account Access

- An AWS account with permissions to create VPCs, ECS clusters, RDS instances, ALBs, IAM roles, and related resources.
- AWS CLI configured with credentials:
  ```bash
  aws configure
  # Enter your Access Key ID, Secret Access Key, region (e.g., us-east-1), and output format (json)
  ```
- Verify access: `aws sts get-caller-identity` should return your account info.

### DNS and SSL (for production)

- A Route53 hosted zone for your domain, or the ability to create DNS records externally.
- An SSL certificate in AWS Certificate Manager (ACM), or set `create_ssl_certificate = true` to have the module create one for you.

---

## Key Concepts (60-Second Terraform Primer)

If you're new to Terraform, here's what you need to know:

- **Module** — A reusable package of `.tf` files that creates a set of related resources. This repo has three modules in `modules/`.
- **Example** — A ready-to-use configuration in `examples/` that wires modules together. You copy an example, fill in your values, and deploy.
- **Variables** — Inputs you provide (like `environment = "dev"`). Defined in `variables.tf`, supplied via `.tfvars` files.
- **Outputs** — Values Terraform returns after deployment (like the ALB DNS name or database endpoint).
- **State** — Terraform tracks what it created in a state file. For team use, store this in an S3 backend (see [backend.tf.example](./complete/backend.tf.example)).
- **Plan → Apply** — `tofu plan` shows what will change. `tofu apply` makes it happen. Always plan before you apply.

---

## Choose Your Starting Point

We provide three examples, each progressively more complete:

| Example | Use Case | Guide |
|---------|----------|-------|
| [foundation-only](./foundation-only/) | Set up shared infrastructure (VPC, database, cluster) before adding apps later | [README](./foundation-only/README.md) |
| [with-solr](./with-solr/) | Foundation + Solr search cluster, without DSpace services | [README](./with-solr/README.md) |
| [complete](./complete/) | Full DSpace deployment with all three modules | [README](./complete/README.md) |

**First time?** Start with `foundation-only` to get comfortable, then layer on additional modules.

**Ready to go?** Jump straight to `complete` for the full stack.

---

## Step-by-Step: Your First Deployment

This walkthrough uses the `foundation-only` example. The same pattern applies to all examples.

### 1. Clone the Repository

```bash
git clone https://github.com/jhu/terraform-aws-jhu-drcc.git
cd terraform-aws-jhu-drcc/examples/foundation-only
```

### 2. Create Your Configuration File

```bash
cp dev.tfvars.example dev.tfvars
```

Open `dev.tfvars` in your editor. The only value you *must* set is `environment`:

```hcl
environment = "dev"
```

Everything else has sensible defaults (small database, standard VPC layout). Override only what you need:

```hcl
# Optional overrides
# organization = "myuniv"          # Default: "jhu"
# db_instance_class = "db.t3.small"  # Default: "db.t3.micro"
```

### 3. Initialize Terraform

This downloads the AWS provider and sets up the working directory:

```bash
tofu init
```

You should see `OpenTofu has been successfully initialized!` (or the Terraform equivalent).

### 4. Preview the Plan

See exactly what Terraform will create before it touches anything:

```bash
tofu plan -var-file=dev.tfvars
```

Review the output. You'll see resources like `aws_vpc.main`, `aws_ecs_cluster.main`, `aws_db_instance.main`, etc. The plan shows `+ create` for new resources.

### 5. Apply

```bash
tofu apply -var-file=dev.tfvars
```

Terraform will show the plan again and ask for confirmation. Type `yes`.

Deployment takes roughly 10–15 minutes (RDS creation is the slowest part). When it finishes, Terraform prints the outputs — VPC ID, ALB DNS name, database endpoint, etc.

### 6. Verify

```bash
# Check ECS cluster exists
aws ecs list-clusters

# Check database is available
aws rds describe-db-instances --query 'DBInstances[].DBInstanceStatus'

# Check ALB is active
aws elbv2 describe-load-balancers --query 'LoadBalancers[].State.Code'
```

---

## Adding Solr (Next Step)

Once the foundation is running, you can add a Solr search cluster. Switch to the `with-solr` example or add the Solr module to your existing configuration:

```bash
cd ../with-solr
cp dev.tfvars.example dev.tfvars
# Edit dev.tfvars with your values
tofu init
tofu apply -var-file=dev.tfvars
```

The Solr module automatically connects to the foundation's VPC, ECS cluster, and load balancers through module outputs. See the [with-solr README](./with-solr/README.md) for configuration options like node count and memory allocation.

---

## Going to Production

When you're ready for a production deployment:

1. Use the [complete](./complete/) example as your starting point
2. Copy and customize `prod.tfvars.example`:
   ```bash
   cd ../complete
   cp prod.tfvars.example prod.tfvars
   ```
3. Update the `[REQUIRED]` values for your institution (domain, bucket names, notification email)
4. Deploy in stages for safety:
   ```bash
   tofu init
   tofu apply -target=module.foundation -var-file=prod.tfvars
   tofu apply -target=module.solr -var-file=prod.tfvars
   tofu apply -target=module.dspace_app -var-file=prod.tfvars
   ```
5. Follow the [Production Deployment Guide](./complete/PRODUCTION.md) for security hardening, scaling, and operational procedures
6. See the [Initialization Guide](./complete/INITIALIZATION.md) for running database migrations and Solr setup on first deploy

---

## Remote State (Recommended for Teams)

By default, Terraform stores state locally in a `terraform.tfstate` file. For team environments, use an S3 backend so everyone shares the same state:

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "myorg-terraform-state"
    key            = "drcc/foundation/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

See [backend.tf.example](./complete/backend.tf.example) for a ready-to-use template. Create the S3 bucket and DynamoDB table before running `tofu init`.

---

## Tearing Down

To destroy all resources created by Terraform:

```bash
tofu destroy -var-file=dev.tfvars
```

Terraform will show everything it plans to delete and ask for confirmation. This is safe for dev/test environments. For production, review the [Production Guide](./complete/PRODUCTION.md) before destroying anything.

---

## Cost Awareness

| Profile | What You Get | Estimated Monthly Cost |
|---------|-------------|----------------------|
| Evaluation | Single-AZ, minimal instances, 1 Solr + 2 DSpace tasks | ~$195–245 |
| Production | Multi-AZ, HA, 5 Solr + 8 DSpace tasks, RDS Multi-AZ | ~$1,660–2,515 |

Tip: Start with the evaluation profile for development. Scale up for staging and production. Use AWS Savings Plans for 30–50% savings on long-running workloads.

---

## Common Issues

**`tofu init` fails with provider errors**
Check your internet connection and that you're running OpenTofu >= 1.6 or Terraform >= 1.0. Run `tofu version` to verify.

**`tofu plan` shows credential errors**
Run `aws sts get-caller-identity` to verify your AWS credentials are configured. If using SSO, run `aws sso login` first.

**RDS creation takes a long time**
This is normal — RDS instances take 8–12 minutes to provision. Multi-AZ deployments take longer.

**ECS tasks fail to start**
Check CloudWatch Logs for the task. Common causes: incorrect IAM permissions, security group rules blocking traffic, or container image pull failures.

**Want to change something after deployment?**
Edit your `.tfvars` file, run `tofu plan` to preview changes, then `tofu apply`. Terraform only modifies what changed.

---

## Where to Go Next

- [Module READMEs](../modules/) — Detailed input/output documentation for each module
  - [drcc-foundation](../modules/drcc-foundation/README.md)
  - [solr-search-cluster](../modules/solr-search-cluster/README.md)
  - [dspace-app-services](../modules/dspace-app-services/README.md)
- [Production Deployment Guide](./complete/PRODUCTION.md) — Security, scaling, and operations
- [Initialization Guide](./complete/INITIALIZATION.md) — Database migration and Solr setup
- [Architecture Analysis](../ARCHITECTURE_ANALYSIS.md) — Design decisions and module boundaries
- [OpenTofu Documentation](https://opentofu.org/docs/) — Learn more about infrastructure as code
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs) — Alternative IaC tool documentation

---

## Getting Help

- Slack: `#dev-ops` (JHU Libraries)
- Email: drcc-devops@jhu.edu
- [GitHub Issues](https://github.com/jhu/terraform-aws-jhu-drcc/issues)
