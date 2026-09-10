output "zone_id" {
  description = "ID of the adopted public Route 53 hosted zone."
  value       = data.aws_route53_zone.this.zone_id
}

output "zone_name" {
  description = "Name of the adopted public Route 53 hosted zone."
  value       = data.aws_route53_zone.this.name
}

output "certificate_arn" {
  description = "ARN of the DNS-validated ACM certificate in us-east-1 (ISSUED)."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "name_servers" {
  description = "Name servers for the adopted hosted zone (confirm registrar delegation)."
  value       = data.aws_route53_zone.this.name_servers
}
