# Lambda container function (Next.js standalone server behind the AWS Lambda
# Web Adapter extension baked into the image) exposed through an
# AWS_IAM-authenticated Function URL. The function, URL, and CloudFront
# permissions only exist once `image_tag` is set, because Lambda cannot be
# created before its image has been pushed to the ECR repository.

locals {
  function_name = "${var.name_prefix}-web"
  create_lambda = var.image_tag != null
  image_uri     = local.create_lambda ? "${aws_ecr_repository.this.repository_url}:${var.image_tag}" : null

  # Gated on a plan-time bool, not the ARN: when the distribution is created
  # in the same apply its ARN is unknown, and count cannot depend on it.
  create_cloudfront_permissions = local.create_lambda && var.allow_cloudfront_invoke
}

resource "aws_cloudwatch_log_group" "this" {
  #checkov:skip=CKV_AWS_158:KMS encryption is opt-in via kms_key_arn; CloudWatch Logs encrypts at rest by default.
  #checkov:skip=CKV_AWS_338:Retention is intentionally short (log_retention_days, default 14) as a v1 cost guard.
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name = "/aws/lambda/${local.function_name}"
  })
}

resource "aws_lambda_function" "this" {
  #checkov:skip=CKV_AWS_50:X-Ray tracing is deferred past v1 with the rest of observability.
  #checkov:skip=CKV_AWS_115:Reserved concurrency is opt-in via reserved_concurrent_executions.
  #checkov:skip=CKV_AWS_116:Invoked synchronously through the Function URL; a DLQ only applies to async invokes.
  #checkov:skip=CKV_AWS_117:The SSR function only calls public AWS endpoints; no VPC resources to reach.
  #checkov:skip=CKV_AWS_173:Environment variables hold non-secret config only; KMS is opt-in via kms_key_arn.
  #checkov:skip=CKV_AWS_272:Code signing does not apply to container image functions.
  count = local.create_lambda ? 1 : 0

  function_name = local.function_name
  role          = aws_iam_role.this.arn
  package_type  = "Image"
  image_uri     = local.image_uri
  architectures = [var.architecture]
  memory_size   = var.memory_size
  timeout       = var.timeout
  kms_key_arn   = var.kms_key_arn

  reserved_concurrent_executions = var.reserved_concurrent_executions

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []

    content {
      variables = var.environment_variables
    }
  }

  tags = merge(var.tags, {
    Name = local.function_name
  })

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy.execution,
    aws_ecr_repository_policy.this,
  ]
}

resource "aws_lambda_function_url" "this" {
  count = local.create_lambda ? 1 : 0

  function_name      = aws_lambda_function.this[0].function_name
  authorization_type = "AWS_IAM"
  invoke_mode        = var.invoke_mode
}

# Function URLs created after October 2025 require the caller to hold both
# lambda:InvokeFunctionUrl and lambda:InvokeFunction.
resource "aws_lambda_permission" "cloudfront_invoke_function_url" {
  count = local.create_cloudfront_permissions ? 1 : 0

  statement_id           = "AllowCloudFrontInvokeFunctionUrl"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this[0].function_name
  principal              = "cloudfront.amazonaws.com"
  source_arn             = var.cloudfront_distribution_arn
  function_url_auth_type = "AWS_IAM"
}

resource "aws_lambda_permission" "cloudfront_invoke_function" {
  count = local.create_cloudfront_permissions ? 1 : 0

  statement_id  = "AllowCloudFrontInvokeFunction"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[0].function_name
  principal     = "cloudfront.amazonaws.com"
  source_arn    = var.cloudfront_distribution_arn
}
