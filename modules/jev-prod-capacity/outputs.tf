# These feed the agentcore.json capacity provider (operatorRoleArn,
# instanceProfileArn, vpcConfiguration.securityGroups/subnets).

output "operator_role_arn" {
  description = "AgentCore capacity-provider operatorRoleArn (null if disabled)."
  value       = try(aws_iam_role.operator[0].arn, null)
}

output "instance_profile_arn" {
  description = "EC2 instanceProfileArn for the fleet launch parameters (null if disabled)."
  value       = try(aws_iam_instance_profile.instance[0].arn, null)
}

output "instance_role_arn" {
  description = "EC2 instance role ARN (null if disabled)."
  value       = try(aws_iam_role.instance[0].arn, null)
}

output "security_group_id" {
  description = "Egress-only security group for the capacity-provider fleet (null if disabled)."
  value       = try(aws_security_group.fleet[0].id, null)
}

output "subnet_ids" {
  description = "Echo of the subnets the capacity provider should use (its vpcConfiguration)."
  value       = var.subnet_ids
}
