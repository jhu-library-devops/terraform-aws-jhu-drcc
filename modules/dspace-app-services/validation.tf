# Variable validation checks
# Note: Terraform variable validation blocks can only reference the variable being validated.
# For cross-variable validation, we use a null_resource with preconditions that will fail during plan.

resource "terraform_data" "validate_task_definition_config" {
  lifecycle {
    precondition {
      condition = var.use_external_task_definitions || (
        var.dspace_api_image != null &&
        var.dspace_angular_image != null &&
        var.dspace_jobs_image != null
      )
      error_message = "When use_external_task_definitions = false, all image variables are required: dspace_api_image, dspace_angular_image, and dspace_jobs_image must be provided."
    }

    precondition {
      condition = !var.use_external_task_definitions || (
        var.dspace_api_task_def_arn != null &&
        var.dspace_angular_task_def_arn != null &&
        var.dspace_jobs_task_def_arn != null
      )
      error_message = "When use_external_task_definitions = true, all external task definition ARN variables are required: dspace_api_task_def_arn, dspace_angular_task_def_arn, and dspace_jobs_task_def_arn must be provided."
    }
  }
}
