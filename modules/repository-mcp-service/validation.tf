resource "terraform_data" "validate_configuration" {
  lifecycle {
    precondition {
      condition = var.use_external_task_definitions ? (
        var.mcp_task_def_arn != null && var.mcp_task_def_arn != ""
        ) : (
        var.mcp_image != null && var.mcp_image != ""
      )
      error_message = "Set mcp_task_def_arn in external mode or mcp_image in Terraform-managed mode."
    }

    precondition {
      condition     = var.service_min_count <= var.service_desired_count && var.service_desired_count <= var.service_max_count
      error_message = "service_desired_count must be between service_min_count and service_max_count."
    }

    precondition {
      condition = var.environment != "prod" || (
        var.service_min_count >= 2 && var.service_desired_count >= 2
      )
      error_message = "Production requires service_min_count and service_desired_count to be at least two."
    }

    precondition {
      condition     = contains(local.valid_fargate_task_sizes[var.task_cpu], var.task_memory)
      error_message = "task_memory is not valid for the selected Fargate task_cpu value."
    }

    precondition {
      condition = (
        var.jhrdr_solr_security_group_id == null &&
        var.jhrdr_api_security_group_id == null &&
        var.jhrdr_solr_url == "" &&
        var.jhrdr_api_url == "" &&
        var.jhrdr_public_url == ""
        ) || (
        var.jhrdr_solr_security_group_id != null &&
        var.jhrdr_api_security_group_id != null &&
        var.jhrdr_solr_url != "" &&
        var.jhrdr_api_url != "" &&
        var.jhrdr_public_url != ""
      )
      error_message = "Configure both JHRDR security groups and all three JHRDR URLs, or leave all JHRDR inputs disabled."
    }
  }
}
