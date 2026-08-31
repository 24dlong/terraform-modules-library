output "bucket_id" {
  description = "Name of the Next.js static assets S3 bucket."
  value       = aws_s3_bucket.assets.id
}

output "bucket_arn" {
  description = "ARN of the Next.js static assets S3 bucket."
  value       = aws_s3_bucket.assets.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the assets bucket (for CloudFront S3 origin config)."
  value       = aws_s3_bucket.assets.bucket_regional_domain_name
}
