# JHU Library Terraform Module Library

A comprehensive library of Terraform / OpenTofu root modules for Infrastructure as Code (IaC) deployment workflows, designed to support JHU Library's cloud and on-premises infrastructure needs.

## Overview

The JHU Terraform Module Library offers a consistent and scalable approach to provisioning and managing our infrastructure. By leveraging these modules, teams can efficiently deploy common resources such as VPCs, databases, and server instances across various environments (e.g., development, staging, production). This library implements living documentation techniques to ensure that our infrastructure code and its documentation evolve together [[5]](https://poe.com/citation?message_id=214644473742&citation=5).

## Key Features

- **Ready-Made Documentation**: Each module includes a detailed README file at its root, providing clear usage instructions, input variables, and resource creation details [[1]](https://poe.com/citation?message_id=214644473742&citation=1)[[2]](https://poe.com/citation?message_id=214644473742&citation=2).
- **Decision Logs**: Important architectural and design decisions are captured in a Markdown file within the base directory of each module [[2]](https://poe.com/citation?message_id=214644473742&citation=2).
- **Code Tagging**: We use custom annotations to highlight key landmarks and core concepts, facilitating easier navigation through the codebase [[2]](https://poe.com/citation?message_id=214644473742&citation=2).
- **Guided Tours**: Annotations provide end-to-end walkthroughs of requests or processing across various code fragments and modules [[2]](https://poe.com/citation?message_id=214644473742&citation=2).
- **Visual Representations**: Where applicable, we include diagrams or visualizations to illustrate complex structures or workflows [[3]](https://poe.com/citation?message_id=214644473742&citation=3).

## Module Catalog

(List your modules here)

## Getting Started

To use the modules in this library:

1. Clone the repository:
   ```
   git clone https://github.com/jhu-library/terraform-module-library.git
   ```

2. Navigate to the desired module directory.

3. Review the module's README for input variables and resource details.

4. In your Terraform configuration, reference the module:

   ```hcl
   module "vpc" {
     source = "../../modules/vpc"
     vpc_cidr = "10.0.0.0/16"
     subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
     # Add other required input variables
   }
   ```

5. Initialize your Terraform workspace:
   ```
   terraform init
   ```
   or for OpenTofu:
   ```
   tofu init
   ```

6. Apply your configuration:
   ```
   terraform apply
   ```
   or
   ```
   tofu apply
   ```

## Versioning and Dependency Management

We adhere to semantic versioning (SemVer) principles. Version numbers follow the format `major.minor.patch`:

- Major: Breaking changes
- Minor: New features (backwards-compatible)
- Patch: Bug fixes (backwards-compatible)

Specify module versions in your configurations to ensure stability:

```hcl
module "vpc" {
  source = "../../modules/vpc?ref=v1.2.3"
  # ...
}
```

## Contribution Guidelines

We welcome contributions! Proceed to [Contributing](./CONTRIBUTING.md)

## Support and Feedback

For questions, issues, or feedback, please visit the #dev-ops channel in the JHU Libraries Slack. We encourage open communication and collaboration to continuously improve our infrastructure and processes [[6]](https://poe.com/citation?message_id=214644473742&citation=6).

## Continuous Improvement

We are committed to maintaining up-to-date and relevant documentation. If you notice any discrepancies between the documentation and the actual code behavior, please report it immediately. Remember, in a living documentation approach, everyone is responsible for keeping the documentation current [[5]](https://poe.com/citation?message_id=214644473742&citation=5).

By leveraging this module library and following these guidelines, we aim to create a more efficient, standardized, and well-documented infrastructure that evolves with our needs and technological advancements [[4]](https://poe.com/citation?message_id=214644473742&citation=4).
