output "role_arn" {
  description = "ARN of the IAM role GitHub Actions assumes via OIDC."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role GitHub Actions assumes via OIDC."
  value       = aws_iam_role.this.name
}

output "oidc_provider_arn" {
  description = "ARN of the token.actions.githubusercontent.com OIDC provider used by this module (created or pre-existing)."
  value       = local.oidc_provider_arn
}
