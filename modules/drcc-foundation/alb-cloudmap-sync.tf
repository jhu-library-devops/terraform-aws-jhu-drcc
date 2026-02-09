# Archive lambda source code
data "archive_file" "alb_cloudmap_sync_zip" {
  type        = "zip"
  source_file = "${path.root}/../aws-lambda/alb-cloudmap-sync-lambda.py"
  output_path = "${path.root}/../aws-lambda/alb-cloudmap-sync.zip"
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${local.name}-alb-cloudmap-sync-lambda-role"

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
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_cloudmap" {
  name = "${local.name}-alb-cloudmap-sync-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "servicediscovery:RegisterInstance",
          "servicediscovery:DeregisterInstance",
          "servicediscovery:DiscoverInstances",
          "servicediscovery:GetInstance",
          "servicediscovery:ListInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetHealth"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function to sync ALB target health with CloudMap
resource "aws_lambda_function" "alb_cloudmap_sync" {
  filename         = data.archive_file.alb_cloudmap_sync_zip.output_path
  function_name    = "${local.name}-alb-cloudmap-sync"
  role             = aws_iam_role.lambda_role.arn
  handler          = "alb-cloudmap-sync-lambda.lambda_handler"
  runtime          = "python3.11"
  timeout          = 60
  source_code_hash = data.archive_file.alb_cloudmap_sync_zip.output_base64sha256

  environment {
    variables = {
      ALB_NAME    = aws_lb.private_alb.name
      SERVICE_ID  = aws_service_discovery_service.solr_alb.id
      INSTANCE_ID = "solr-alb"
    }
  }
}

# EventBridge rule to trigger Lambda on ALB network interface changes
resource "aws_cloudwatch_event_rule" "alb_cloudmap_sync" {
  name        = "${local.name}-alb-cloudmap-sync"
  description = "Trigger ALB CloudMap sync when ALB network interfaces change"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "AttachNetworkInterface",
        "CreateNetworkInterface",
        "DeleteNetworkInterface"
      ]
      requestParameters = {
        description = [{
          prefix = "ELB app/${aws_lb.private_alb.name}/"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "alb_cloudmap_sync" {
  rule      = aws_cloudwatch_event_rule.alb_cloudmap_sync.name
  target_id = "${local.name}-alb-cloudmap-sync"
  arn       = aws_lambda_function.alb_cloudmap_sync.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alb_cloudmap_sync.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alb_cloudmap_sync.arn
}
