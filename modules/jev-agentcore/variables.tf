# jev-agentcore module inputs.
# No provider/backend/profile concerns here — the calling root owns those.
# No environment defaults for identity values — the root supplies them.

variable "namespace" {
  description = "Resource name prefix component (house convention: namespace + environment)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. aiops, dev, prod)."
  type        = string
}

variable "decider_runtime_arn" {
  description = <<-EOT
    ARN of the Bedrock AgentCore Runtime created by the AgentCore CLI in the
    consuming project. Example:
    arn:aws:bedrock-agentcore:us-east-1:390157243417:runtime/JevDeciders_jev-XXXXXX
  EOT
  type        = string

  validation {
    condition     = can(regex("^arn:aws:bedrock-agentcore:", var.decider_runtime_arn))
    error_message = "decider_runtime_arn must be a bedrock-agentcore runtime ARN."
  }
}

# ---- feature toggles -------------------------------------------------------
variable "warmup_enabled" {
  description = "Create the pre-business-hours EventBridge warm-up ping (Posture A)."
  type        = bool
  default     = true
}

variable "decision_log_enabled" {
  description = "Create a DynamoDB decision log + idempotency table for the agent's rulings."
  type        = bool
  default     = true
}

# ---- warm-up tuning --------------------------------------------------------
variable "warmup_schedule_expression" {
  description = <<-EOT
    EventBridge Scheduler cron for the warm-up ping. Evaluated in
    warmup_timezone. Default: 07:55 local Mon–Fri, just before business hours.
  EOT
  type        = string
  default     = "cron(55 7 ? * MON-FRI *)"
}

variable "warmup_timezone" {
  description = "IANA timezone for the warm-up schedule (EventBridge Scheduler honors it, avoiding manual DST math)."
  type        = string
  default     = "America/New_York"
}

variable "warmup_session_id" {
  description = <<-EOT
    Stable AgentCore session id the warm-up ping reuses so it keeps ONE replica
    warm. Must be >= 33 characters (AgentCore runtimeSessionId minimum).
  EOT
  type        = string
  default     = "jev-warmup-session-0000000000000000"

  validation {
    condition     = length(var.warmup_session_id) >= 33
    error_message = "warmup_session_id must be at least 33 characters (AgentCore runtimeSessionId minimum)."
  }
}

variable "warmup_lambda_timeout" {
  description = "Warm-up Lambda timeout (s). A microVM cold start can take ~45-90s."
  type        = number
  default     = 180
}

# ---- decision log tuning ---------------------------------------------------
variable "decision_log_point_in_time_recovery" {
  description = "Enable PITR on the decision-log table."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags merged onto this module's resources (in addition to the provider default_tags set by the root)."
  type        = map(string)
  default     = {}
}
