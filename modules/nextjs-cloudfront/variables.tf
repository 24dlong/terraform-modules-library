variable "name_prefix" {
  description = "Prefix used to name every resource (e.g. \"myapp-prod\"). Resources are named \"<name_prefix>-web\" plus a suffix where needed."
  type        = string
}

variable "tags" {
  description = "Common tags merged into every resource created by this module."
  type        = map(string)
  default     = {}
}

variable "domain_name" {
  description = <<-EOT
    Apex domain the distribution serves (e.g. `"example.com"`). The
    distribution's aliases are the apex and `www.<domain_name>`; `www` is the
    canonical hostname. DNS records are not created by this module.
  EOT
  type        = string

  validation {
    condition     = !startswith(var.domain_name, "www.")
    error_message = "domain_name must be the apex domain, without a \"www.\" prefix."
  }
}

variable "acm_certificate_arn" {
  description = "ARN of an issued ACM certificate in `us-east-1` covering `domain_name` and `www.<domain_name>`."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:acm:us-east-1:", var.acm_certificate_arn))
    error_message = "acm_certificate_arn must be an ACM certificate in us-east-1 (CloudFront requirement)."
  }
}

variable "lambda_function_url" {
  description = "AWS_IAM-authenticated Lambda Function URL (the `nextjs-lambda` module's `function_url` output), e.g. `https://abc123.lambda-url.us-east-2.on.aws/`. Serves SSR and, unless `s3_bucket_regional_domain_name` is set, static assets."
  type        = string
}

variable "serve_static_assets_from_s3" {
  description = <<-EOT
    Whether `/_next/static/*` is served from the assets bucket
    (`s3_bucket_regional_domain_name`) through an S3 origin access control.
    When `false`, the Lambda origin serves static assets too and CloudFront
    caches them. Only enable once the release pipeline uploads each build's
    static files to the bucket, and grant this distribution read access in
    the bucket policy. A plain bool so it can be planned while the bucket
    domain name is still unknown.
  EOT
  type        = bool
  default     = false
}

variable "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the static assets bucket (the `nextjs-assets` module's `bucket_regional_domain_name` output). Only used when `serve_static_assets_from_s3` is `true`."
  type        = string
  default     = null

  validation {
    condition     = !var.serve_static_assets_from_s3 || var.s3_bucket_regional_domain_name != null
    error_message = "s3_bucket_regional_domain_name is required when serve_static_assets_from_s3 is true."
  }
}

variable "redirect_apex_to_www" {
  description = "Whether requests to the apex `domain_name` get a `301` redirect to `https://www.<domain_name>` (same path and query string)."
  type        = bool
  default     = true
}

variable "allowed_methods" {
  description = <<-EOT
    HTTP methods CloudFront accepts and forwards to the Lambda origin. Must be
    one of the sets CloudFront supports. Requests with a body (e.g. `POST`)
    only reach a Lambda origin behind OAC when the client sends an
    `x-amz-content-sha256` header with the SHA-256 of the body, so the
    default only allows read methods.
  EOT
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS"]

  validation {
    condition = contains([
      join(",", sort(["GET", "HEAD"])),
      join(",", sort(["GET", "HEAD", "OPTIONS"])),
      join(",", sort(["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"])),
    ], join(",", sort(var.allowed_methods)))
    error_message = "allowed_methods must be [GET, HEAD], [GET, HEAD, OPTIONS], or all seven methods (DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT)."
  }
}

variable "price_class" {
  description = "CloudFront price class. `PriceClass_100` serves from US, Canada, and Europe edge locations only, to minimize cost."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}
