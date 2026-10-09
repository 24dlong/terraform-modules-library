output "distribution_id" {
  description = "ID of the CloudFront distribution (for cache invalidations)."
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution. Pass to `nextjs-lambda` (and `nextjs-assets` when serving static assets from S3) as `cloudfront_distribution_arn`."
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "CloudFront domain name of the distribution (e.g. `d111111abcdef8.cloudfront.net`), the target of Route 53 alias records."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_hosted_zone_id" {
  description = "Route 53 hosted zone ID of the distribution, for alias records."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "aliases" {
  description = "Hostnames the distribution serves (apex and `www`); each needs A and AAAA alias records."
  value       = local.aliases
}
