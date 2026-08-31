variable "name_prefix" {
  description = "Prefix used to name the assets bucket (e.g. \"myapp-prod\"). The bucket is named \"<name_prefix>-assets\"."
  type        = string
}

variable "tags" {
  description = "Common tags merged into every resource created by this module."
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = <<-EOT
    Whether to allow Terraform to destroy the assets bucket even if it still
    contains objects. Must remain `false` in any environment that holds real
    application assets; only intended for disposable test/example deployments.
  EOT
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = <<-EOT
    ARN of a customer-managed KMS key used to encrypt the assets bucket. When
    omitted (`null`), the bucket uses the default Amazon S3-managed encryption
    key (SSE-S3).
  EOT
  type        = string
  default     = null
}

variable "cloudfront_distribution_arn" {
  description = <<-EOT
    ARN of the CloudFront distribution allowed to read objects from this
    bucket via Origin Access Control (OAC). When omitted (`null`), the
    CloudFront GetObject statement is not created and the bucket stays
    fully private (no CloudFront access). Pass the distribution ARN in a
    later apply once the distribution exists.
  EOT
  type        = string
  default     = null
}

variable "access_log_bucket" {
  description = <<-EOT
    Name of an existing S3 bucket to receive server access logs for the assets
    bucket. When omitted (`null`), access logging is not configured; provide
    a dedicated logging bucket to satisfy access-logging requirements.
  EOT
  type        = string
  default     = null
}

variable "access_log_prefix" {
  description = "Key prefix applied to access log objects delivered to `access_log_bucket`."
  type        = string
  default     = "nextjs-assets/"
}

variable "noncurrent_version_expiration_days" {
  description = <<-EOT
    Number of days to retain noncurrent (superseded) object versions before
    they are permanently expired. Set to `0` to disable expiration and retain
    all historical versions indefinitely.
  EOT
  type        = number
  default     = 90
}
