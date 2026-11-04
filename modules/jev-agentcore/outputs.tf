output "invoke_policy_arn" {
  description = "IAM policy ARN granting bedrock-agentcore:InvokeAgentRuntime on the Jev runtime. Attach to any caller principal."
  value       = aws_iam_policy.invoke.arn
}

output "invoke_policy_name" {
  description = "Name of the invoke IAM policy."
  value       = aws_iam_policy.invoke.name
}

output "decision_log_table_name" {
  description = "DynamoDB decision-log / idempotency table name (null if decision_log_enabled = false)."
  value       = try(aws_dynamodb_table.decision_log[0].name, null)
}

output "decision_log_table_arn" {
  description = "DynamoDB decision-log table ARN (null if disabled)."
  value       = try(aws_dynamodb_table.decision_log[0].arn, null)
}

output "warmup_function_name" {
  description = "Warm-up Lambda function name (null if warmup_enabled = false)."
  value       = try(aws_lambda_function.warmup[0].function_name, null)
}

output "warmup_function_arn" {
  description = "Warm-up Lambda function ARN (null if disabled)."
  value       = try(aws_lambda_function.warmup[0].arn, null)
}

output "warmup_schedule_name" {
  description = "EventBridge Scheduler schedule name for the warm-up ping (null if disabled)."
  value       = try(aws_scheduler_schedule.warmup[0].name, null)
}
