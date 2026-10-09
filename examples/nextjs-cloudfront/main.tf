# Wiring example for validate and Checkov: nextjs-lambda and
# nextjs-cloudfront referencing each other in one root, applied once.
# Not expected to apply as-is: the certificate ARN and domain are
# placeholders, and the distribution needs an issued us-east-1 certificate
# for that domain.

terraform {
  required_version = ">= 1.9, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46.0, < 7.0.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

variable "image_tag" {
  description = "Tag of an image already pushed to the example ECR repository. The distribution is only created once this is set."
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Apex domain served by the distribution."
  type        = string
  default     = "example.com"
}

variable "acm_certificate_arn" {
  description = "Issued us-east-1 ACM certificate covering the apex and www."
  type        = string
  default     = "arn:aws:acm:us-east-1:111111111111:certificate/00000000-0000-0000-0000-000000000000"
}

locals {
  name_prefix = "example-app-prod"
  tags = {
    Project     = "example-app"
    Environment = "production"
  }
}

module "nextjs_lambda" {
  source = "../../modules/nextjs-lambda"

  name_prefix = local.name_prefix
  image_tag   = var.image_tag
  tags        = local.tags

  allow_cloudfront_invoke     = var.image_tag != null
  cloudfront_distribution_arn = one(module.nextjs_cloudfront[*].distribution_arn)

  # Disposable example only; keep false wherever real images live.
  force_delete = true
}

module "nextjs_cloudfront" {
  source = "../../modules/nextjs-cloudfront"
  count  = var.image_tag != null ? 1 : 0

  name_prefix         = local.name_prefix
  domain_name         = var.domain_name
  acm_certificate_arn = var.acm_certificate_arn
  lambda_function_url = module.nextjs_lambda.function_url
  tags                = local.tags
}

output "distribution_domain_name" {
  value = one(module.nextjs_cloudfront[*].distribution_domain_name)
}
