# Adopt an existing public Route 53 hosted zone and issue a DNS-validated
# ACM certificate in us-east-1 (required for CloudFront). Intended caller is
# per-application shared infrastructure — not a multi-app platform root —
# so each app's cert lives in its own Terraform state.
#
# ACM-for-CloudFront must live in us-east-1. Callers remap this module's
# default aws provider to a us-east-1 configuration (Route 53 is global, so
# the same provider is fine for validation records):
#
#   provider "aws" {
#     alias  = "us_east_1"
#     region = "us-east-1"
#   }
#
#   module "route53_acm" {
#     source = "..."
#     providers = {
#       aws = aws.us_east_1
#     }
#     domain_name = "example.com"
#   }

data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  tags = merge(var.tags, {
    Name = var.domain_name
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}
