output "training_bucket_name" {
  description = "S3 bucket for labelled data + model artifacts (null if training disabled)."
  value       = var.training_enabled ? aws_s3_bucket.artifacts[0].bucket : null
}

output "training_role_arn" {
  description = "SageMaker training-job execution role ARN — pass to sagemaker_launch.py --role-arn (null if disabled)."
  value       = var.training_enabled ? aws_iam_role.training[0].arn : null
}

output "data_prefix" {
  description = "Suggested s3:// prefix for prepared train/eval JSONL (null if disabled)."
  value       = var.training_enabled ? "s3://${aws_s3_bucket.artifacts[0].bucket}/data/" : null
}

output "artifacts_prefix" {
  description = "Suggested s3:// prefix for model artifacts — sagemaker_launch.py --output (null if disabled)."
  value       = var.training_enabled ? "s3://${aws_s3_bucket.artifacts[0].bucket}/artifacts/" : null
}
