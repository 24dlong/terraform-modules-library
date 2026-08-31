terraform {
  required_version = ">= 1.9, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 7.0.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

module "nextjs_assets" {
  source = "../../modules/nextjs-assets"

  name_prefix = "example-app-prod"

  tags = {
    Project     = "example-app"
    Environment = "production"
  }
}

output "bucket_id" {
  value = module.nextjs_assets.bucket_id
}

output "bucket_arn" {
  value = module.nextjs_assets.bucket_arn
}

output "bucket_regional_domain_name" {
  value = module.nextjs_assets.bucket_regional_domain_name
}
