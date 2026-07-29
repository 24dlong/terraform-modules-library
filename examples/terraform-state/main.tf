terraform {
  required_version = ">= 1.9, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

module "terraform_state" {
  source = "../../modules/terraform-state"

  name_prefix = "example-app-prod"

  tags = {
    Project     = "example-app"
    Environment = "production"
  }
}

output "bucket_id" {
  value = module.terraform_state.bucket_id
}

output "bucket_arn" {
  value = module.terraform_state.bucket_arn
}
