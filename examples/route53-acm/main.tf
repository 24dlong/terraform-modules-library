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

# ACM certificates used with CloudFront must be in us-east-1. Remap the
# module's default aws provider to this alias (see module README).
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Placeholder domain — replace with a real public Route 53 hosted zone before
# `terraform apply`. `fmt` / `validate` / Checkov succeed without AWS access;
# apply requires the zone to exist and (for ISSUED) registrar NS delegation.
module "route53_acm" {
  source = "../../modules/route53-acm"

  providers = {
    aws = aws.us_east_1
  }

  domain_name = "example.com"

  tags = {
    Project     = "example-app"
    Environment = "production"
  }
}

output "zone_id" {
  value = module.route53_acm.zone_id
}

output "zone_name" {
  value = module.route53_acm.zone_name
}

output "certificate_arn" {
  value = module.route53_acm.certificate_arn
}

output "name_servers" {
  value = module.route53_acm.name_servers
}
