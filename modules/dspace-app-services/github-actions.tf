# GitHub Actions IAM Roles for CI/CD Pipeline
# These roles allow GitHub Actions workflows to deploy and test infrastructure

# OIDC Identity Provider for GitHub Actions (assumed to exist)
data "aws_iam_openid_connect_provider" "github_actions" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# Main GitHub Actions role for deployment
resource "aws_iam_role" "github_actions_role" {
  name        = "GitHubActionsRole"
  description = "Role for GitHub Actions to deploy infrastructure"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:jhu-sheridan-libraries/jhu-dspace-deployment:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "GitHubActionsRole"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "OpenTofu"
    Purpose     = "CI/CD"
  }
}

# Inline policy for GitHub Actions deployment permissions
resource "aws_iam_role_policy" "github_actions_permissions" {
  name = "GitHubActionsPermissions"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "application-autoscaling:*",
          "cloudwatch:*",
          "dynamodb:*",
          "ec2:*",
          "ecr:*",
          "ecs:*",
          "elasticloadbalancing:*",
          "events:DescribeRule",
          "events:ListTagsForResource",
          "events:ListTargetsByRule",
          "iam:AttachRolePolicy",
          "iam:CreateRole",
          "iam:GetOpenIDConnectProvider",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:PassRole",
          "iam:PutRolePolicy",
          "logs:*",
          "rds:*",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource",
          "s3:*",
          "secretsmanager:*",
          "servicediscovery:*",
          "sns:*",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })
}

# GitHub Actions test role for Terratest integration tests
resource "aws_iam_role" "github_actions_test_role" {
  name        = "GitHubActions-Test-Role"
  description = "Role for GitHub Actions Terratest integration tests"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:jhu-sheridan-libraries/jhu-dspace-deployment:pull_request"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "GitHubActions-Test-Role"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "OpenTofu"
    Purpose     = "Testing"
    Owner       = "devops"
    System      = "dspace"
  }
}

# Attach AdministratorAccess policy to test role for comprehensive testing
resource "aws_iam_role_policy_attachment" "github_actions_test_admin_policy" {
  role       = aws_iam_role.github_actions_test_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
