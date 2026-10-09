variable "name_prefix" {
  description = "Prefix used to name every resource (e.g. \"myapp-prod\"). The ECR repository is \"<name_prefix>-web\" and the Lambda function is \"<name_prefix>-web\"."
  type        = string
}

variable "tags" {
  description = "Common tags merged into every resource created by this module."
  type        = map(string)
  default     = {}
}

variable "image_tag" {
  description = <<-EOT
    Tag of the container image in this module's ECR repository to run (e.g.
    the application release version `"1.4.0"`). The image URI is built as
    `<ecr_repository_url>:<image_tag>`. When omitted (`null`), only the ECR
    repository, IAM role, and log group are created; the Lambda function,
    Function URL, and CloudFront permissions are created once a tag is set
    and that image has been pushed.
  EOT
  type        = string
  default     = null
}

variable "allow_cloudfront_invoke" {
  description = <<-EOT
    Whether to grant `cloudfront_distribution_arn` permission to invoke the
    Function URL. Requires `cloudfront_distribution_arn`. This is a separate
    flag so the permissions can be planned while the distribution ARN is
    still unknown (distribution created in the same apply).
  EOT
  type        = bool
  default     = false
}

variable "cloudfront_distribution_arn" {
  description = <<-EOT
    ARN of the CloudFront distribution allowed to invoke the Function URL via
    Origin Access Control (OAC). Only used when `allow_cloudfront_invoke` is
    `true`; may come straight from the `nextjs-cloudfront` module's
    `distribution_arn` output in the same root. Without it, the Function URL
    is only reachable with signed IAM requests from principals in this
    account.
  EOT
  type        = string
  default     = null

  validation {
    condition     = !var.allow_cloudfront_invoke || var.cloudfront_distribution_arn != null
    error_message = "cloudfront_distribution_arn is required when allow_cloudfront_invoke is true."
  }
}

variable "architecture" {
  description = "Instruction set architecture of the Lambda function. Must match the pushed image's platform."
  type        = string
  default     = "arm64"

  validation {
    condition     = contains(["arm64", "x86_64"], var.architecture)
    error_message = "architecture must be \"arm64\" or \"x86_64\"."
  }
}

variable "memory_size" {
  description = "Amount of memory in MB available to the Lambda function."
  type        = number
  default     = 1024
}

variable "timeout" {
  description = "Lambda function timeout in seconds."
  type        = number
  default     = 15

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "timeout must be between 1 and 900 seconds."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain the Lambda function's CloudWatch logs. Must be a value CloudWatch Logs accepts; `0` (never expire) is intentionally not allowed."
  type        = number
  default     = 14

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a CloudWatch Logs retention value (1, 3, 5, 7, 14, 30, ... 3653); 0 (never expire) is not allowed."
  }
}

variable "invoke_mode" {
  description = <<-EOT
    Function URL invoke mode. `BUFFERED` returns the full response at once;
    `RESPONSE_STREAM` streams it and requires the image to run the Lambda Web
    Adapter with `AWS_LWA_INVOKE_MODE=response_stream`.
  EOT
  type        = string
  default     = "BUFFERED"

  validation {
    condition     = contains(["BUFFERED", "RESPONSE_STREAM"], var.invoke_mode)
    error_message = "invoke_mode must be \"BUFFERED\" or \"RESPONSE_STREAM\"."
  }
}

variable "environment_variables" {
  description = <<-EOT
    Non-secret environment variables for the Lambda function (e.g.
    `AWS_LWA_PORT`, `AWS_LWA_READINESS_CHECK_PATH`, `NODE_ENV`). Values are
    stored in Terraform state and visible in the Lambda console; deliver
    secrets through Secrets Manager (`secret_arns`) instead.
  EOT
  type        = map(string)
  default     = {}
}

variable "secret_arns" {
  description = <<-EOT
    ARNs of Secrets Manager secrets the function may read with
    `secretsmanager:GetSecretValue` at startup. Secrets encrypted with a
    customer-managed KMS key also need `kms:Decrypt` on that key, granted via
    `additional_policy_arns` or the key policy.
  EOT
  type        = list(string)
  default     = []
}

variable "additional_policy_arns" {
  description = "ARNs of additional IAM managed policies to attach to the Lambda execution role."
  type        = list(string)
  default     = []
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrency for the Lambda function. `null` leaves the function on the account's unreserved concurrency pool."
  type        = number
  default     = null
}

variable "force_delete" {
  description = <<-EOT
    Whether to allow Terraform to delete the ECR repository even if it still
    contains images. Must remain `false` in any environment that holds real
    application images; only intended for disposable test/example deployments.
  EOT
  type        = bool
  default     = false
}

variable "image_retention_count" {
  description = "Number of most recent tagged images kept in the ECR repository. Older tagged images expire, so keep this above the number of releases you may need to roll back to."
  type        = number
  default     = 20

  validation {
    condition     = var.image_retention_count >= 1
    error_message = "image_retention_count must be at least 1."
  }
}

variable "untagged_image_expiration_days" {
  description = "Number of days after push that untagged images (e.g. intermediate build layers) are expired from the ECR repository."
  type        = number
  default     = 7

  validation {
    condition     = var.untagged_image_expiration_days >= 1
    error_message = "untagged_image_expiration_days must be at least 1."
  }
}

variable "kms_key_arn" {
  description = <<-EOT
    ARN of a customer-managed KMS key used to encrypt the ECR repository, the
    CloudWatch log group, and the function's environment variables. The key
    policy must allow the CloudWatch Logs service principal for this region.
    When omitted (`null`), AWS-managed encryption is used for all three.
  EOT
  type        = string
  default     = null
}
