# jev-prod-capacity module inputs.
# Supporting IAM + networking for an AgentCore capacity provider that backs the
# `jev-prod` runtime with dedicated, powerful EC2 compute (c7g.4xlarge, on-demand).
# A capacity provider REQUIRES an operator role and an EC2 instance profile; none
# pre-exist, so this module creates them least-privilege. VPC/subnets are reused
# (passed in), and it creates one dedicated egress-only security group.
# No provider/backend/profile here — the calling root owns those.

variable "namespace" {
  description = "Resource name prefix component (house convention: namespace + environment)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. aiops, prod)."
  type        = string
}

variable "prod_capacity_enabled" {
  description = <<-EOT
    Create the capacity-provider supporting infra (operator role, instance
    profile, security group). Off by default — the prod runtime is a separate,
    always-on-cost posture from the scale-to-zero Posture-A runtime.
  EOT
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC the capacity-provider instances run in (reused existing VPC)."
  type        = string
  default     = ""

  validation {
    condition     = var.vpc_id == "" || can(regex("^vpc-[0-9a-f]{8,17}$", var.vpc_id))
    error_message = "vpc_id must be a vpc-... id or empty."
  }
}

variable "subnet_ids" {
  description = "Private subnets (>= 1, multi-AZ recommended) for the capacity-provider instances."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Extra tags merged onto this module's resources (in addition to provider default_tags)."
  type        = map(string)
  default     = {}
}
