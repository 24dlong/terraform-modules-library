variable "name_prefix" {
  description = "Prefix used to name the Terraform state bucket (e.g. \"myapp-prod\")."
  type        = string
}

variable "tags" {
  description = "Common tags merged into every resource created by this module."
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = <<-EOT
    Whether to allow Terraform to destroy the state bucket even if it still
    contains objects (including prior state file versions). Must remain
    `false` in any environment that holds real Terraform state; only intended
    for disposable test/example deployments.
  EOT
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = <<-EOT
    ARN of a customer-managed KMS key used to encrypt the state bucket. When
    omitted (`null`), the bucket uses the default Amazon S3-managed encryption
    key (SSE-S3).
  EOT
  type        = string
  default     = null
}

variable "access_log_bucket" {
  description = <<-EOT
    Name of an existing S3 bucket to receive server access logs for the state
    bucket. When omitted (`null`), access logging is not configured; provide
    a dedicated logging bucket to satisfy access-logging requirements.
  EOT
  type        = string
  default     = null
}

variable "access_log_prefix" {
  description = "Key prefix applied to access log objects delivered to `access_log_bucket`."
  type        = string
  default     = "terraform-state/"
}

variable "noncurrent_version_expiration_days" {
  description = <<-EOT
    Number of days to retain noncurrent (superseded) state file versions
    before they are permanently expired. Set to `0` to disable expiration and
    retain all historical versions indefinitely.
  EOT
  type        = number
  default     = 90
}
