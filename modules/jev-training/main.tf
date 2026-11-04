locals {
  name_prefix = "${var.namespace}-${var.environment}-jev"
  bucket_name = var.artifacts_bucket_name != "" ? var.artifacts_bucket_name : "${local.name_prefix}-training"
  create      = var.training_enabled
  # Where the role may read/write. Scopes the SageMaker role to this bucket only.
  bucket_arn     = local.create ? aws_s3_bucket.artifacts[0].arn : ""
  bucket_objects = local.create ? "${aws_s3_bucket.artifacts[0].arn}/*" : ""
}

############################################
# Training data + artifacts bucket (private)
############################################
resource "aws_s3_bucket" "artifacts" {
  count         = local.create ? 1 : 0
  bucket        = local.bucket_name
  force_destroy = var.artifacts_force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  count                   = local.create ? 1 : 0
  bucket                  = aws_s3_bucket.artifacts[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  count  = local.create ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  count  = local.create ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  count  = local.create && var.artifact_expiration_days > 0 ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    id     = "expire-old-artifacts"
    status = "Enabled"
    filter {
      prefix = "artifacts/"
    }
    expiration {
      days = var.artifact_expiration_days
    }
    noncurrent_version_expiration {
      noncurrent_days = var.artifact_expiration_days
    }
  }
}

############################################
# SageMaker training execution role (least privilege, scoped to the bucket)
############################################
data "aws_iam_policy_document" "sagemaker_assume" {
  count = local.create ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "training" {
  count              = local.create ? 1 : 0
  name               = "${local.name_prefix}-training"
  description        = "SageMaker training-job execution role for fine-tuning the Jev decider."
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume[0].json
  tags               = var.tags
}

# Read/write ONLY the training bucket (data in, artifacts out).
data "aws_iam_policy_document" "training_s3" {
  count = local.create ? 1 : 0
  statement {
    sid       = "ListTrainingBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [local.bucket_arn]
  }
  statement {
    sid       = "ReadWriteTrainingObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [local.bucket_objects]
  }
}

resource "aws_iam_role_policy" "training_s3" {
  count  = local.create ? 1 : 0
  name   = "training-bucket-access"
  role   = aws_iam_role.training[0].id
  policy = data.aws_iam_policy_document.training_s3[0].json
}

# CloudWatch logs + ECR pull for the training container, scoped to SageMaker.
data "aws_iam_policy_document" "training_ops" {
  count = local.create ? 1 : 0
  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/sagemaker/*"]
  }
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
}

resource "aws_iam_role_policy" "training_ops" {
  count  = local.create ? 1 : 0
  name   = "training-logs-ecr"
  role   = aws_iam_role.training[0].id
  policy = data.aws_iam_policy_document.training_ops[0].json
}
