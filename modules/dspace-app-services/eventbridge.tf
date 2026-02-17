# EventBridge rules for DSpace scheduled jobs
# These rules trigger ECS tasks to run various DSpace maintenance jobs

locals {
  # Define DSpace job configurations
  dspace_jobs = {
    checker = {
      description         = "DSpace checker job - runs weekly on Mondays at 8 AM UTC"
      schedule_expression = "cron(0 8 ? * 1 *)"
      command             = "/dspace/bin/dspace checker -d 1h -p"
    }
    cleanup = {
      description         = "DSpace cleanup job - runs monthly on the 1st at 5:22 AM UTC"
      schedule_expression = "cron(22 5 1 * ? *)"
      command             = "/dspace/bin/dspace cleanup"
    }
    filter-media = {
      description         = "DSpace filter media job - runs daily at 7 AM UTC"
      schedule_expression = "cron(0 7 * * ? *)"
      command             = "FROM_DATE=$(date -d '1 week ago' +%Y-%m-%d) && echo 'From Date: '$FROM_DATE && /dspace/bin/dspace filter-media -d $FROM_DATE"
    }
    index-authority = {
      description         = "DSpace index authority job - runs daily at 4:45 AM UTC"
      schedule_expression = "cron(45 4 * * ? *)"
      command             = "/dspace/bin/dspace index-authority"
    }
    index-discovery = {
      description         = "DSpace index discovery job - runs daily at 4:10 AM UTC"
      schedule_expression = "cron(10 4 * * ? *)"
      command             = "/dspace/bin/dspace index-discovery"
    }
    oai-import = {
      description         = "DSpace OAI import job - runs daily at 4:05 AM UTC"
      schedule_expression = "cron(5 4 * * ? *)"
      command             = "/dspace/bin/dspace oai import"
    }
    stats-util = {
      description         = "DSpace stats util job - runs daily at 5 AM UTC"
      schedule_expression = "cron(0 5 * * ? *)"
      command             = "/dspace/bin/dspace stats-util -f"
    }
    subscription-send = {
      description         = "DSpace subscription send job - runs daily at 6 AM UTC"
      schedule_expression = "cron(0 6 * * ? *)"
      command             = "/dspace/bin/dspace subscription-send -f D"
    }
    subscription-send-w = {
      description         = "DSpace subscription send weekly job - runs weekly on Mondays at 6 AM UTC"
      schedule_expression = "cron(0 6 ? * 1 *)"
      command             = "/dspace/bin/dspace subscription-send -f W"
    }
    stats-export = {
      description         = "DSpace statistics export job - runs monthly on the 1st at 2 AM UTC"
      schedule_expression = "cron(0 2 1 * ? *)"
      command             = "/dspace/bin/dspace solr-export-statistics -i statistics -l m -d /tmp && echo 'Export complete, uploading to S3...' && MONTH=$(date -d 'last month' +%Y-%m) && aws s3 sync /tmp/ s3://${aws_s3_bucket.statistics_exports.bucket}/$MONTH/ && echo 'Upload complete to s3://${aws_s3_bucket.statistics_exports.bucket}/$MONTH/'"
    }
    statistics-import = {
      description = "DSpace statistics import job - manual trigger only"
      event_pattern = jsonencode({
        source      = ["dspace.statistics"]
        detail-type = ["Statistics Import"]
      })
      command = "aws s3 sync s3://${aws_s3_bucket.statistics_exports.bucket}/full/ /tmp/stats/ && /dspace/bin/dspace solr-import-statistics -d /tmp/stats/"
    }
    stats-export-daily = {
      description         = "DSpace statistics export job - runs nightly at 2 AM UTC"
      schedule_expression = "cron(0 2 * * ? *)"
      command             = "/dspace/bin/dspace solr-export-statistics -i statistics -l d -d /tmp && echo 'Export complete, uploading to S3...' && DATE=$(date +%Y-%m-%d) && aws s3 sync /tmp/ s3://${aws_s3_bucket.statistics_exports.bucket}/daily/$DATE/ && echo 'Upload complete to s3://${aws_s3_bucket.statistics_exports.bucket}/daily/$DATE/'"
    }
    stats-full-export = {
      description = "DSpace full statistics export job - manual execution"
      event_pattern = jsonencode({
        source = ["manual"]
      })
      command = "/dspace/bin/dspace solr-export-statistics -i statistics -l a -d /tmp && echo 'Export complete, uploading to S3...' && aws s3 sync /tmp/ s3://${aws_s3_bucket.statistics_exports.bucket}/full/ && echo 'Upload complete to s3://${aws_s3_bucket.statistics_exports.bucket}/full/'"
    }
  }
}

# EventBridge rules for DSpace scheduled jobs
resource "aws_cloudwatch_event_rule" "dspace_jobs" {
  for_each = local.dspace_jobs

  name                = "${var.project_name}-${var.environment}-job-${each.key}"
  description         = each.value.description
  schedule_expression = lookup(each.value, "schedule_expression", null)
  event_pattern       = lookup(each.value, "event_pattern", null)
  state               = "ENABLED"

  tags = {
    Name        = "${var.project_name}-${var.environment}-job-${each.key}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "OpenTofu"
    JobType     = each.key
  }
}

# EventBridge targets for DSpace jobs
resource "aws_cloudwatch_event_target" "dspace_jobs" {
  for_each = local.dspace_jobs

  rule      = aws_cloudwatch_event_rule.dspace_jobs[each.key].name
  target_id = "${var.project_name}-${var.environment}-job-${each.key}"
  arn       = var.ecs_cluster_arn
  role_arn  = aws_iam_role.eventbridge_ecs_role.arn

  input = jsonencode({
    containerOverrides = [
      {
        name = "${var.organization}-${var.environment}-dspace-jobs"
        command = [
          "/bin/bash",
          "-c",
          "echo '+++Log:${var.project_name}-${var.environment}-job-${each.key}+++' && ${each.value.command} && echo 'Job completed successfully' || (echo 'Job failed with exit code $?' && exit 1)"
        ]
      }
    ]
  })

  ecs_target {
    task_definition_arn     = var.dspace_jobs_task_def_arn
    task_count              = 1
    launch_type             = "FARGATE"
    platform_version        = "LATEST"
    enable_ecs_managed_tags = false
    enable_execute_command  = false
    propagate_tags          = "TASK_DEFINITION"

    network_configuration {
      subnets          = [var.private_subnet_ids[0]]
      security_groups  = [var.ecs_security_group_id]
      assign_public_ip = false
    }
  }

  depends_on = [
    aws_iam_role.eventbridge_ecs_role
  ]
}

# IAM role for EventBridge to execute ECS tasks
resource "aws_iam_role" "eventbridge_ecs_role" {
  name = "${local.name}-ecs-events-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${local.name}-ecs-events-role"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "OpenTofu"
  }
}

# Attach AWS managed policy for EventBridge ECS integration
resource "aws_iam_role_policy_attachment" "eventbridge_ecs_policy" {
  role       = aws_iam_role.eventbridge_ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

# Inline policy for SSM parameter access
resource "aws_iam_role_policy" "eventbridge_ecs_ssm_policy" {
  name = "dspace-${var.environment}-ecs-params-policy"
  role = aws_iam_role.eventbridge_ecs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/dspace/${var.environment}/*"
        ]
      }
    ]
  })
}
