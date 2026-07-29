output "bucket_id" {
  description = "Name of the Terraform state S3 bucket."
  value       = aws_s3_bucket.state.id
}

output "bucket_arn" {
  description = "ARN of the Terraform state S3 bucket."
  value       = aws_s3_bucket.state.arn
}

output "bucket_region" {
  description = "AWS region the Terraform state S3 bucket was created in."
  value       = aws_s3_bucket.state.region
}
