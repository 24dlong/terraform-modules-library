output "ecr_repository_url" {
  description = "URL of the ECR repository the application publishes images to (`<account>.dkr.ecr.<region>.amazonaws.com/<name>`)."
  value       = aws_ecr_repository.this.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository (for granting the application repo's CI push access)."
  value       = aws_ecr_repository.this.arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.this.name
}

output "execution_role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.this.arn
}

output "execution_role_name" {
  description = "Name of the Lambda execution role (for attaching extra inline policies outside this module)."
  value       = aws_iam_role.this.name
}

output "log_group_name" {
  description = "Name of the Lambda function's CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.name
}

output "image_uri" {
  description = "Image URI the function runs (`<ecr_repository_url>:<image_tag>`). `null` until `image_tag` is set."
  value       = local.image_uri
}

output "function_name" {
  description = "Name of the Lambda function. `null` until `image_tag` is set."
  value       = one(aws_lambda_function.this[*].function_name)
}

output "function_arn" {
  description = "ARN of the Lambda function. `null` until `image_tag` is set."
  value       = one(aws_lambda_function.this[*].arn)
}

output "function_url" {
  description = "AWS_IAM-authenticated Function URL (the CloudFront Lambda origin). `null` until `image_tag` is set."
  value       = one(aws_lambda_function_url.this[*].function_url)
}
