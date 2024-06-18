# JHU Library Terraform Module Library
A library of Terraform / Tofu root modules for Infrastructure As Code (IAC) deployment workflows.

## Overview

The JHU Terraform Module Library is designed to provide a consistent and scalable way to provision and manage our cloud and on-prem infrastructure. By using these modules, teams can quickly and reliably deploy common resources, such as VPCs, databases, and server instances, across different environments (e.g., development, staging, production).

## Module Catalog

The following modules are currently available in this library:


## Getting Started

Each module has its own README file, which provides detailed instructions on how to use the module, its input variables, and the resources it creates.

To use the modules in this library, follow these steps:

1. Clone the repository to your local machine:
`git clone https://github.com/your-org/enterprise-terraform-modules.git`

2. Navigate to the module you want to use (e.g., `terraform-module-library/vpc`).

3. Review the module's README file to understand the required input variables and the resources it creates.

4. In your Terraform configuration, reference the module using the `source` attribute:

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr = "10.0.0.0/16"
  subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  # Add other required input variables
}
```

Run 
`tofu init` or `terraform init`
 to download the module and its dependencies.

Run 
`tofu apply` or `terraform apply`
 to provision the resources defined in your configuration.

## Versioning and Dependency Management
This module library follows semantic versioning principles. Each module has a version number in the format 
major.minor.patch. When making changes to a module, we adhere to the following guidelines:

Major version changes: Breaking changes that are not backward-compatible.

Minor version changes: New features or enhancements that are backward-compatible.

Patch version changes: Bug fixes that are backward-compatible.

To manage dependencies, we use version constraints in the source attribute of the module blocks. For example, source = "../../modules/vpc?ref=v1.2.3" will use the `v1.2.3` version of the VPC module.

## Contribution Guidelines
We welcome contributions to this module library. If you have a new module or an improvement to an existing one, please follow these steps:

Fork the repository.

Create a new branch for your changes.

Implement your changes and update the module's README file.

Run 
`tofu format` or `terraform fmt`
 to ensure consistent code formatting.

Test your changes in a non-production environment.

Submit a pull request with a detailed description of your changes.

All pull requests will be reviewed by the infrastructure team before being merged.

## Support and Feedback
If you have any questions, issues, or feedback regarding this module library, please visit #dev-ops channel in the JHU Libraries Slack.
