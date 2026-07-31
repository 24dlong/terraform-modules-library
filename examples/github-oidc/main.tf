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

module "github_oidc" {
  source = "../../modules/github-oidc"

  name_prefix = "example-app-prod"

  create_oidc_provider = true

  github_org    = "24dlong"
  github_repo   = "example-app-infra"
  github_branch = "main"

  # Real consumers attach their own least-privilege permissions here, e.g.:
  # managed_policy_arns = [aws_iam_policy.deploy.arn]

  tags = {
    Project     = "example-app"
    Environment = "production"
  }
}

output "role_arn" {
  value = module.github_oidc.role_arn
}

output "oidc_provider_arn" {
  value = module.github_oidc.oidc_provider_arn
}
