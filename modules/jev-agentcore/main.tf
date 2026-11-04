locals {
  name_prefix = "${var.namespace}-${var.environment}-jev"
}

############################################
# Invoke policy: who may call Jev's runtime
############################################
# Attach the output policy ARN to any principal (a Lambda, an ECS task role, a
# service account) that needs to ask Jev a question. AgentCore uses IAM/SigV4
# auth, so this is the gate.
data "aws_iam_policy_document" "invoke" {
  statement {
    sid       = "InvokeJevRuntime"
    effect    = "Allow"
    actions   = ["bedrock-agentcore:InvokeAgentRuntime"]
    resources = [var.decider_runtime_arn]
  }
}

resource "aws_iam_policy" "invoke" {
  name        = "${local.name_prefix}-invoke"
  description = "Allow invoking the Jev (Strands Decider) AgentCore runtime."
  policy      = data.aws_iam_policy_document.invoke.json
  tags        = var.tags
}

############################################
# Decision log + idempotency (runtime table, not TF state)
############################################
resource "aws_dynamodb_table" "decision_log" {
  count = var.decision_log_enabled ? 1 : 0

  name         = "${local.name_prefix}-decisions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "decision_id"

  attribute {
    name = "decision_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = var.decision_log_point_in_time_recovery
  }

  tags = var.tags
}

############################################
# Warm-up ping (Posture A): keep one replica warm before business hours
############################################
data "aws_iam_policy_document" "warmup_assume" {
  count = var.warmup_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "warmup" {
  count              = var.warmup_enabled ? 1 : 0
  name               = "${local.name_prefix}-warmup"
  assume_role_policy = data.aws_iam_policy_document.warmup_assume[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "warmup_basic" {
  count      = var.warmup_enabled ? 1 : 0
  role       = aws_iam_role.warmup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "warmup_invoke" {
  count      = var.warmup_enabled ? 1 : 0
  role       = aws_iam_role.warmup[0].name
  policy_arn = aws_iam_policy.invoke.arn
}

data "archive_file" "warmup" {
  count       = var.warmup_enabled ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambda/warmup/handler.py"
  output_path = "${path.module}/.build/warmup.zip"
}

resource "aws_lambda_function" "warmup" {
  count            = var.warmup_enabled ? 1 : 0
  function_name    = "${local.name_prefix}-warmup"
  role             = aws_iam_role.warmup[0].arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  timeout          = var.warmup_lambda_timeout
  filename         = data.archive_file.warmup[0].output_path
  source_code_hash = data.archive_file.warmup[0].output_base64sha256

  environment {
    variables = {
      DECIDER_RUNTIME_ARN = var.decider_runtime_arn
      WARMUP_SESSION_ID   = var.warmup_session_id
    }
  }

  tags = var.tags
}

# EventBridge Scheduler (honors a timezone, so no manual DST math).
data "aws_iam_policy_document" "scheduler_assume" {
  count = var.warmup_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  count              = var.warmup_enabled ? 1 : 0
  name               = "${local.name_prefix}-warmup-sched"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume[0].json
  tags               = var.tags
}

data "aws_iam_policy_document" "scheduler_invoke_lambda" {
  count = var.warmup_enabled ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.warmup[0].arn]
  }
}

resource "aws_iam_role_policy" "scheduler_invoke_lambda" {
  count  = var.warmup_enabled ? 1 : 0
  name   = "invoke-warmup"
  role   = aws_iam_role.scheduler[0].id
  policy = data.aws_iam_policy_document.scheduler_invoke_lambda[0].json
}

resource "aws_scheduler_schedule" "warmup" {
  count = var.warmup_enabled ? 1 : 0
  name  = "${local.name_prefix}-warmup"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.warmup_schedule_expression
  schedule_expression_timezone = var.warmup_timezone

  target {
    arn      = aws_lambda_function.warmup[0].arn
    role_arn = aws_iam_role.scheduler[0].arn
  }
}
