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

variable "image_tag" {
  description = "Tag of an image already pushed to the example ECR repository. Leave null for the first apply."
  type        = string
  default     = null
}

module "nextjs_lambda" {
  source = "../../modules/nextjs-lambda"

  name_prefix = "example-app-prod"
  image_tag   = var.image_tag

  # Disposable example only; keep false wherever real images live.
  force_delete = true

  tags = {
    Project     = "example-app"
    Environment = "production"
  }
}

output "ecr_repository_url" {
  value = module.nextjs_lambda.ecr_repository_url
}

output "function_url" {
  value = module.nextjs_lambda.function_url
}
