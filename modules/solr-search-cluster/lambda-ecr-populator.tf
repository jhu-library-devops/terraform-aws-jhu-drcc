# Lambda function for populating ECR repositories with upstream container images

data "archive_file" "ecr_populator_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/ecr-image-populator"
  output_path = "${path.module}/lambda/ecr-image-populator.zip"
  excludes    = ["__pycache__", "*.pyc", "test_*.py"]
}

# Lambda function resource
resource "aws_lambda_function" "ecr_image_populator" {
  filename         = data.archive_file.ecr_populator_zip.output_path
  function_name    = "${local.name}-ecr-image-populator"
  role             = aws_iam_role.ecr_populator_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.ecr_populator_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = 900  # 15 minutes
  memory_size      = 1024 # 1GB for Docker operations

  environment {
    variables = {
      AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id
      AWS_REGION     = var.aws_region
    }
  }

  tags = local.tags
}


# IAM role for Lambda function
resource "aws_iam_role" "ecr_populator_role" {
  name = "${local.name}-ecr-populator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}


# IAM policy for ECR operations and CloudWatch Logs
resource "aws_iam_role_policy" "ecr_populator_policy" {
  name = "${local.name}-ecr-populator-policy"
  role = aws_iam_role.ecr_populator_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = [
          for repo in local.ecr_repositories :
          "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${repo}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.name}-ecr-image-populator:*"
      }
    ]
  })
}


# Trigger resource to invoke Lambda when configuration changes
resource "terraform_data" "ecr_image_populator_trigger" {
  triggers_replace = {
    ecr_repositories = jsonencode(local.ecr_repositories)
    solr_image_tag   = var.solr_image_tag
    zookeeper_image  = var.zookeeper_image
    organization     = var.organization
    deploy_zookeeper = var.deploy_zookeeper
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws lambda invoke \
        --function-name ${aws_lambda_function.ecr_image_populator.function_name} \
        --payload '${jsonencode(local.image_populator_payload)}' \
        --region ${var.aws_region} \
        --profile drcc-admin \
        /tmp/lambda-response-${local.name}.json
    EOT
  }

  depends_on = [
    aws_ecr_repository.repositories,
    aws_lambda_function.ecr_image_populator
  ]
}
