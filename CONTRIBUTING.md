# Contributing to JHU Library Terraform Module Library

We're thrilled that you're interested in contributing to our Terraform Module Library! This document provides guidelines for contributing to ensure a smooth collaboration process.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Code of Conduct](#code-of-conduct)
3. [How to Contribute](#how-to-contribute)
4. [Style Guide](#style-guide)
5. [Documentation Guidelines](#documentation-guidelines)
6. [Testing](#testing)
7. [Submitting Changes](#submitting-changes)
8. [Review Process](#review-process)

## Getting Started

Before you begin, ensure you have:

- A GitHub account
- Familiarity with Git and GitHub
- Understanding of Terraform/OpenTofu
- Reviewed our existing modules and documentation

## Code of Conduct

We expect all contributors to adhere to the JHU Libraries Code of Conduct. Please ensure you've read and understood it before contributing.

## How to Contribute

1. Fork the repository
2. Create a new branch for your changes
3. Make your changes, following our [Style Guide](#style-guide) and [Documentation Guidelines](#documentation-guidelines)
4. Test your changes thoroughly
5. Submit a pull request

## Style Guide

- Follow the [HashiCorp Terraform Style Guide](https://developer.hashicorp.com/terraform/language/syntax/style)
- Use meaningful variable and resource names
- Comment complex logic or non-obvious decisions
- Use custom annotations to highlight key landmarks or core concepts [[1]](https://poe.com/citation?message_id=214645527438&citation=1)[[2]](https://poe.com/citation?message_id=214645527438&citation=2)

## Documentation Guidelines

We believe in living documentation. When contributing:

1. Update the README.md in the module directory with any changes to inputs, outputs, or functionality
2. Maintain a decision log (DECISIONS.md) in the module's base directory for significant architectural or design decisions [[2]](https://poe.com/citation?message_id=214645527438&citation=2)
3. Use code tagging for guided tours through complex workflows [[2]](https://poe.com/citation?message_id=214645527438&citation=2)
4. Include ASCII diagrams in the decision log for important concepts [[6]](https://poe.com/citation?message_id=214645527438&citation=6)
5. Ensure all public interfaces, classes, and main methods have clear comments [[4]](https://poe.com/citation?message_id=214645527438&citation=4)

Remember, documentation is part of the code. Keep it up-to-date as you make changes [[5]](https://poe.com/citation?message_id=214645527438&citation=5).

## Testing

- Write and update tests for all new features and bug fixes
- Ensure all existing tests pass before submitting your changes
- Use `terraform validate` and `terraform plan` (or `tofu validate` and `tofu plan`) to check for potential issues

## Submitting Changes

1. Push your changes to your fork
2. Create a pull request with a clear title and description
3. Link any relevant issues in the pull request description
4. Be prepared to respond to feedback and make adjustments

## Review Process

All contributions will be reviewed by the infrastructure team. We may suggest changes or improvements. This process ensures high-quality, consistent modules that meet JHU Libraries' needs.

Thank you for contributing to the JHU Library Terraform Module Library! Your efforts help us maintain a robust, efficient, and well-documented infrastructure.
