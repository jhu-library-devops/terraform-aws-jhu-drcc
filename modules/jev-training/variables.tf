# jev-training module inputs.
# Optional fine-tuning infra: an S3 bucket for labelled data + model artifacts,
# and a least-privilege SageMaker execution role scoped to that bucket. Disabled
# by default — the serving path (jev-agentcore) does not depend on it.
# No provider/backend/profile concerns here; the calling root owns those.

variable "namespace" {
  description = "Resource name prefix component (house convention: namespace + environment)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. aiops, dev, prod)."
  type        = string
}

variable "training_enabled" {
  description = "Create the fine-tuning S3 bucket + SageMaker training role. Off by default."
  type        = bool
  default     = false
}

variable "artifacts_bucket_name" {
  description = <<-EOT
    Name of the S3 bucket for labelled data (data/) and model artifacts
    (artifacts/). Empty => "<namespace>-<environment>-jev-training". Must be
    globally unique if you override it.
  EOT
  type        = string
  default     = ""
}

variable "artifacts_force_destroy" {
  description = "Allow `tofu destroy` to delete a non-empty training bucket. Keep false in shared accounts."
  type        = bool
  default     = false
}

variable "artifact_expiration_days" {
  description = "Lifecycle: expire objects under artifacts/ after N days (0 = never). Keeps old checkpoints from piling up."
  type        = number
  default     = 180
}

variable "tags" {
  description = "Extra tags merged onto this module's resources (in addition to the provider default_tags set by the root)."
  type        = map(string)
  default     = {}
}
