# CloudFront distribution in front of a Next.js app: SSR from an
# AWS_IAM-authenticated Lambda Function URL, and `/_next/static/*` either
# cached from that same origin or served from a private S3 bucket. Both
# origins are reached through origin access control (SigV4), so neither is
# usable directly once its resource policy only trusts this distribution.

locals {
  lambda_origin_id = "lambda"
  s3_origin_id     = "s3-assets"

  lambda_origin_domain = trimsuffix(trimprefix(var.lambda_function_url, "https://"), "/")
  static_origin_id     = var.serve_static_assets_from_s3 ? local.s3_origin_id : local.lambda_origin_id

  aliases = [var.domain_name, "www.${var.domain_name}"]
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

# Forwards every viewer header, cookie, and query string except Host, which
# must stay the Function URL's own domain for routing and the OAC signature.
data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_origin_access_control" "lambda" {
  name                              = "${var.name_prefix}-web-lambda"
  description                       = "SigV4 signing for the ${var.name_prefix}-web Function URL origin"
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_control" "s3" {
  count = var.serve_static_assets_from_s3 ? 1 : 0

  name                              = "${var.name_prefix}-web-assets"
  description                       = "SigV4 signing for the ${var.name_prefix} assets bucket origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_response_headers_policy" "security" {
  #checkov:skip=CKV_AWS_259:HSTS preload is opt-in per domain (hard to undo once on browser preload lists); max-age, includeSubDomains, and override match the check.
  name    = "${var.name_prefix}-web-security-headers"
  comment = "Baseline security headers for ${var.domain_name}"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = false
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}

resource "aws_cloudfront_distribution" "this" {
  #checkov:skip=CKV_AWS_68:WAF is intentionally deferred past v1 and documented as such.
  #checkov:skip=CKV2_AWS_47:WAF (and its Log4j rule set) is intentionally deferred past v1.
  #checkov:skip=CKV_AWS_86:Access logging is deferred past v1 with the rest of observability.
  #checkov:skip=CKV_AWS_310:A single regional Lambda origin has no failover target.
  #checkov:skip=CKV_AWS_374:The public site is not geo-restricted.
  #checkov:skip=CKV_AWS_305:SSR serves "/" from the Lambda origin; there is no root object.
  enabled         = true
  comment         = "${var.name_prefix}-web"
  aliases         = local.aliases
  price_class     = var.price_class
  http_version    = "http2and3"
  is_ipv6_enabled = true

  origin {
    origin_id                = local.lambda_origin_id
    domain_name              = local.lambda_origin_domain
    origin_access_control_id = aws_cloudfront_origin_access_control.lambda.id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  dynamic "origin" {
    for_each = var.serve_static_assets_from_s3 ? [1] : []

    content {
      origin_id                = local.s3_origin_id
      domain_name              = var.s3_bucket_regional_domain_name
      origin_access_control_id = aws_cloudfront_origin_access_control.s3[0].id
    }
  }

  default_cache_behavior {
    target_origin_id           = local.lambda_origin_id
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = var.allowed_methods
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.viewer_request.arn
    }
  }

  # Build output with content-hashed file names; Next.js marks it immutable,
  # and CachingOptimized honors that with a long TTL.
  ordered_cache_behavior {
    path_pattern               = "/_next/static/*"
    target_origin_id           = local.static_origin_id
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.viewer_request.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-web"
  })
}
