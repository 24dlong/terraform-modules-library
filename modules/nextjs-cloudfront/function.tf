resource "aws_cloudfront_function" "viewer_request" {
  name    = "${var.name_prefix}-web-viewer-request"
  runtime = "cloudfront-js-2.0"
  comment = "Apex to www redirect and x-forwarded-host for ${var.domain_name}"
  publish = true

  code = templatefile("${path.module}/functions/viewer_request.js", {
    apex_domain          = lower(var.domain_name)
    redirect_apex_to_www = var.redirect_apex_to_www
  })
}
