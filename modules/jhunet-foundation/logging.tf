# CloudWatch log group for batch/ETL task output
resource "aws_cloudwatch_log_group" "ecs_tasks" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days
  tags              = local.tags
}
