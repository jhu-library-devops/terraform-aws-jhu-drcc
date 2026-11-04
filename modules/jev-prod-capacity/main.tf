locals {
  name_prefix = "${var.namespace}-${var.environment}-jev-prod"
  create      = var.prod_capacity_enabled
}

############################################
# Operator role — AgentCore assumes this to manage the capacity provider's
# EC2 fleet (launch/terminate instances in the given subnets) on your behalf.
############################################
data "aws_iam_policy_document" "operator_assume" {
  count = local.create ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["bedrock-agentcore.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "operator" {
  count              = local.create ? 1 : 0
  name               = "${local.name_prefix}-operator"
  description        = "AgentCore capacity-provider operator role for the Jev prod runtime (manages the EC2 fleet)."
  assume_role_policy = data.aws_iam_policy_document.operator_assume[0].json
  tags               = var.tags
}

# EC2 fleet management scoped to this account/region; PassRole limited to the
# instance role so the operator can only hand instances their own profile.
data "aws_iam_policy_document" "operator" {
  count = local.create ? 1 : 0

  statement {
    sid    = "ManageFleet"
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:CreateTags",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeImages",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateLaunchTemplateVersion",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "PassInstanceRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.instance[0].arn]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "operator" {
  count  = local.create ? 1 : 0
  name   = "capacity-operator"
  role   = aws_iam_role.operator[0].id
  policy = data.aws_iam_policy_document.operator[0].json
}

############################################
# Instance role + profile — what the c7g.4xlarge instances run as. They pull
# the runtime container from ECR, write CloudWatch logs, and are managed by SSM.
############################################
data "aws_iam_policy_document" "instance_assume" {
  count = local.create ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  count              = local.create ? 1 : 0
  name               = "${local.name_prefix}-instance"
  description        = "EC2 instance role for the Jev prod capacity-provider fleet (ECR pull, logs, SSM)."
  assume_role_policy = data.aws_iam_policy_document.instance_assume[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "instance_ssm" {
  count      = local.create ? 1 : 0
  role       = aws_iam_role.instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "instance" {
  count = local.create ? 1 : 0

  statement {
    sid    = "EcrPull"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/bedrock-agentcore/*"]
  }
}

resource "aws_iam_role_policy" "instance" {
  count  = local.create ? 1 : 0
  name   = "instance-ecr-logs"
  role   = aws_iam_role.instance[0].id
  policy = data.aws_iam_policy_document.instance[0].json
}

resource "aws_iam_instance_profile" "instance" {
  count = local.create ? 1 : 0
  name  = "${local.name_prefix}-instance"
  role  = aws_iam_role.instance[0].name
  tags  = var.tags
}

############################################
# Dedicated egress-only security group in the reused VPC. The fleet needs
# outbound (ECR, S3/HF base-model download, logs); no inbound is required —
# AgentCore reaches the runtime through its own managed path, not an open port.
############################################
resource "aws_security_group" "fleet" {
  count       = local.create ? 1 : 0
  name        = "${local.name_prefix}-fleet"
  description = "Jev prod capacity-provider fleet: egress only (ECR/S3/logs); no inbound."
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound (ECR, base-model download, CloudWatch logs)."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-fleet" })
}
