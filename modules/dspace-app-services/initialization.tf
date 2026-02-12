# ECS Task-Based Initialization
# One-time tasks for database migration and Solr setup

# Database initialization task definition
resource "aws_ecs_task_definition" "db_init" {
  family                   = "${var.organization}-${var.environment}-${var.project_name}-db-init"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "db-init"
      image = var.dspace_api_image != null ? var.dspace_api_image : "dspace/dspace:latest"
      
      command = [
        "/bin/bash",
        "-c",
        "dspace database migrate && dspace create-administrator -e admin@example.com -f Admin -l User -p admin -c en"
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.init.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "db-init"
        }
      }

      environment = [
        {
          name  = "DSPACE_INSTALL_DIR"
          value = "/dspace"
        }
      ]

      secrets = var.db_secret_arn != null ? [
        {
          name      = "DB_HOST"
          valueFrom = "${var.db_secret_arn}:host::"
        },
        {
          name      = "DB_PORT"
          valueFrom = "${var.db_secret_arn}:port::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "${var.db_secret_arn}:dbname::"
        },
        {
          name      = "DB_USER"
          valueFrom = "${var.db_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.db_secret_arn}:password::"
        }
      ] : []
    }
  ])

  tags = local.tags
}

# Solr initialization task definition
resource "aws_ecs_task_definition" "solr_init" {
  family                   = "${var.organization}-${var.environment}-${var.project_name}-solr-init"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "solr-init"
      image = var.dspace_api_image != null ? var.dspace_api_image : "dspace/dspace:latest"
      
      command = [
        "/bin/bash",
        "-c",
        "dspace solr-import-collections"
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.init.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "solr-init"
        }
      }

      environment = [
        {
          name  = "DSPACE_INSTALL_DIR"
          value = "/dspace"
        },
        {
          name  = "SOLR_SERVER"
          value = var.solr_url
        }
      ]

      secrets = var.db_secret_arn != null ? [
        {
          name      = "DB_HOST"
          valueFrom = "${var.db_secret_arn}:host::"
        },
        {
          name      = "DB_PORT"
          valueFrom = "${var.db_secret_arn}:port::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "${var.db_secret_arn}:dbname::"
        },
        {
          name      = "DB_USER"
          valueFrom = "${var.db_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.db_secret_arn}:password::"
        }
      ] : []
    }
  ])

  tags = local.tags
}

# CloudWatch log group for initialization tasks
resource "aws_cloudwatch_log_group" "init" {
  name              = "/ecs/${var.environment}-dspace-init"
  retention_in_days = 7
  tags              = local.tags
}

# Lambda function to run initialization tasks
resource "aws_lambda_function" "run_init_tasks" {
  count = var.enable_init_tasks ? 1 : 0

  filename      = data.archive_file.init_lambda[0].output_path
  function_name = "${var.organization}-${var.environment}-${var.project_name}-init-tasks"
  role          = aws_iam_role.init_lambda[0].arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 900

  source_code_hash = data.archive_file.init_lambda[0].output_base64sha256

  environment {
    variables = {
      CLUSTER_ARN           = var.ecs_cluster_arn
      DB_INIT_TASK_DEF      = aws_ecs_task_definition.db_init.arn
      SOLR_INIT_TASK_DEF    = aws_ecs_task_definition.solr_init.arn
      SUBNET_IDS            = jsonencode(var.private_subnet_ids)
      SECURITY_GROUP_ID     = var.ecs_security_group_id
      ENABLE_PUBLIC_IP      = "false"
    }
  }

  tags = local.tags
}

# Lambda function code
data "archive_file" "init_lambda" {
  count = var.enable_init_tasks ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/init_lambda.zip"

  source {
    content  = file("${path.module}/init_lambda.py")
    filename = "index.py"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "init_lambda" {
  count = var.enable_init_tasks ? 1 : 0

  name = "${var.organization}-${var.environment}-${var.project_name}-init-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "init_lambda" {
  count = var.enable_init_tasks ? 1 : 0

  name = "${var.organization}-${var.environment}-${var.project_name}-init-lambda-policy"
  role = aws_iam_role.init_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          var.ecs_task_execution_role_arn,
          var.ecs_task_role_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "init_lambda_basic" {
  count = var.enable_init_tasks ? 1 : 0

  role       = aws_iam_role.init_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
