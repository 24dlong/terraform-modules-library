# nextjs-cloudfront

CloudFront distribution that is the public edge for a Next.js app deployed
with `nextjs-lambda` (SSR through an `AWS_IAM` Function URL) and optionally
`nextjs-assets` (static files in a private S3 bucket). Serves the apex and
`www.<domain_name>` with an existing `us-east-1` ACM certificate; `www` is
canonical and the apex redirects to it.

What it creates:

- Origin access control (SigV4, `always`) for the Lambda Function URL, and
  for the S3 bucket when `serve_static_assets_from_s3` is `true`.
- A viewer-request CloudFront Function on every behavior. It returns a
  `301` from the apex to `https://www.<domain_name>` (same path and query
  string), and copies the viewer's `Host` into `x-forwarded-host`.
- A response headers policy: HSTS (1 year, `includeSubDomains`, no
  `preload`), `X-Content-Type-Options: nosniff`, `X-Frame-Options:
  SAMEORIGIN`, and `Referrer-Policy: strict-origin-when-cross-origin`. No
  Content-Security-Policy, since that depends on the app; set it in the
  app or extend this policy.
- The distribution: HTTPS only (HTTP redirects), TLS 1.2 (`TLSv1.2_2021`)
  minimum, SNI, HTTP/2 and HTTP/3, IPv6, `PriceClass_100` by default.

It does not create DNS records, the Lambda invoke permissions, or the
bucket policy. Those belong to the caller, `nextjs-lambda`, and
`nextjs-assets` respectively.

See [`docs/MODULE_STANDARDS.md`](../../docs/MODULE_STANDARDS.md) for this
repository's versioning and consumption conventions. See
[`examples/nextjs-cloudfront`](../../examples/nextjs-cloudfront) for the
wiring below in one root.

## Cache behaviors

| Path | Origin | Cache policy | Origin request policy |
| --- | --- | --- | --- |
| Default (`*`) | Lambda | `Managed-CachingDisabled` | `Managed-AllViewerExceptHostHeader` |
| `/_next/static/*` | Lambda, or S3 when `serve_static_assets_from_s3` | `Managed-CachingOptimized` | none |

The viewer's `Host` header is never forwarded to the Lambda origin. The
Function URL routes on `Host`, and the OAC signature covers it. Next.js
reads the public hostname from `x-forwarded-host` instead.

SSR responses are not cached at the edge. `/_next/static/*` files have
content-hashed names, and Next.js marks them immutable, so they are cached
for a long time.

## Static assets: Lambda (default) or S3

By default the Lambda origin also serves `/_next/static/*`. The image
already contains the build output, so no upload step is needed. The cost is
that a request missing the edge cache invokes Lambda. A page load
requests many files in parallel, so a cold cache (for example right after a
deploy, which changes every file name) can start several Lambda instances
at once. Clients still holding the previous release's HTML can also ask for
chunks that only the old image had, and Next.js recovers with a full page
reload ("deployment skew").

Set `serve_static_assets_from_s3 = true` once the release pipeline uploads
each build's `.next/static` files to the bucket under `_next/static/`
without deleting earlier releases' files. Then pass this distribution's
ARN to `nextjs-assets` as well.

## Wiring with nextjs-lambda and nextjs-assets (single apply)

The modules reference each other, but no single resource depends on itself
through them: the distribution needs the Function URL; the Lambda
permissions and bucket policy need the distribution ARN. One root and one
apply works:

```hcl
module "nextjs_lambda" {
  source = "git::https://github.com/24dlong/terraform-modules-library.git//modules/nextjs-lambda?ref=<version>"

  name_prefix = local.name_prefix
  image_tag   = var.image_tag

  allow_cloudfront_invoke     = var.image_tag != null
  cloudfront_distribution_arn = one(module.nextjs_cloudfront[*].distribution_arn)
}

module "nextjs_cloudfront" {
  source = "git::https://github.com/24dlong/terraform-modules-library.git//modules/nextjs-cloudfront?ref=<version>"
  count  = var.image_tag != null ? 1 : 0

  name_prefix         = local.name_prefix
  domain_name         = data.terraform_remote_state.app_shared.outputs.domain_name
  acm_certificate_arn = data.terraform_remote_state.app_shared.outputs.acm_certificate_arn
  lambda_function_url = module.nextjs_lambda.function_url
}
```

- Gate the distribution on `image_tag`: the Function URL only exists once an
  image tag is set.
- `allow_cloudfront_invoke` (and `serve_static_assets_from_s3` here) are
  plain bools on purpose. The distribution ARN and bucket domain name are
  unknown until created, and `count` cannot depend on unknown values.
- When serving static assets from S3, also set
  `serve_static_assets_from_s3 = true`,
  `s3_bucket_regional_domain_name = module.nextjs_assets.bucket_regional_domain_name`,
  and `cloudfront_distribution_arn` on `nextjs-assets`.
- Point A and AAAA alias records for each of `aliases` at
  `distribution_domain_name` / `distribution_hosted_zone_id`.

## Request methods and OAC

With OAC, CloudFront signs requests to the Function URL. For requests with a
body (`POST`, `PUT`, `PATCH`), the signature needs the body's SHA-256, which
the client must send in an `x-amz-content-sha256` header; CloudFront does
not compute it. Browsers don't send it, so Next.js Server Actions and form
`POST`s fail through this origin. The default `allowed_methods` is therefore
`GET`, `HEAD`, `OPTIONS`. Allow all methods only if the clients that send
bodies set that header.

## Verification

The distribution can't be applied standalone: it needs an issued
certificate and a live Function URL. After applying through a consumer
root:

```sh
curl -sI https://www.<domain>/                   # 200, from Lambda through CloudFront
curl -sI https://<domain>/some/path?q=1          # 301 to https://www.<domain>/some/path?q=1
curl -sI https://www.<domain>/_next/static/...   # 200, x-cache shows Hit after the first request
curl -sI "$(terraform output -raw function_url)" # 403: unsigned requests are denied
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.46.0, < 7.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.68.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.viewer_request](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_cloudfront_origin_access_control.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_cloudfront_origin_access_control.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_cloudfront_response_headers_policy.security](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_response_headers_policy) | resource |
| [aws_cloudfront_cache_policy.caching_disabled](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_cache_policy.caching_optimized](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_origin_request_policy.all_viewer_except_host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_origin_request_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | ARN of an issued ACM certificate in `us-east-1` covering `domain_name` and `www.<domain_name>`. | `string` | n/a | yes |
| <a name="input_allowed_methods"></a> [allowed\_methods](#input\_allowed\_methods) | HTTP methods CloudFront accepts and forwards to the Lambda origin. Must be<br/>one of the sets CloudFront supports. Requests with a body (e.g. `POST`)<br/>only reach a Lambda origin behind OAC when the client sends an<br/>`x-amz-content-sha256` header with the SHA-256 of the body, so the<br/>default only allows read methods. | `list(string)` | <pre>[<br/>  "GET",<br/>  "HEAD",<br/>  "OPTIONS"<br/>]</pre> | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Apex domain the distribution serves (e.g. `"example.com"`). The<br/>distribution's aliases are the apex and `www.<domain_name>`; `www` is the<br/>canonical hostname. DNS records are not created by this module. | `string` | n/a | yes |
| <a name="input_lambda_function_url"></a> [lambda\_function\_url](#input\_lambda\_function\_url) | AWS\_IAM-authenticated Lambda Function URL (the `nextjs-lambda` module's `function_url` output), e.g. `https://abc123.lambda-url.us-east-2.on.aws/`. Serves SSR and, unless `s3_bucket_regional_domain_name` is set, static assets. | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used to name every resource (e.g. "myapp-prod"). Resources are named "<name\_prefix>-web" plus a suffix where needed. | `string` | n/a | yes |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | CloudFront price class. `PriceClass_100` serves from US, Canada, and Europe edge locations only, to minimize cost. | `string` | `"PriceClass_100"` | no |
| <a name="input_redirect_apex_to_www"></a> [redirect\_apex\_to\_www](#input\_redirect\_apex\_to\_www) | Whether requests to the apex `domain_name` get a `301` redirect to `https://www.<domain_name>` (same path and query string). | `bool` | `true` | no |
| <a name="input_s3_bucket_regional_domain_name"></a> [s3\_bucket\_regional\_domain\_name](#input\_s3\_bucket\_regional\_domain\_name) | Regional domain name of the static assets bucket (the `nextjs-assets` module's `bucket_regional_domain_name` output). Only used when `serve_static_assets_from_s3` is `true`. | `string` | `null` | no |
| <a name="input_serve_static_assets_from_s3"></a> [serve\_static\_assets\_from\_s3](#input\_serve\_static\_assets\_from\_s3) | Whether `/_next/static/*` is served from the assets bucket<br/>(`s3_bucket_regional_domain_name`) through an S3 origin access control.<br/>When `false`, the Lambda origin serves static assets too and CloudFront<br/>caches them. Only enable once the release pipeline uploads each build's<br/>static files to the bucket, and grant this distribution read access in<br/>the bucket policy. A plain bool so it can be planned while the bucket<br/>domain name is still unknown. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags merged into every resource created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_aliases"></a> [aliases](#output\_aliases) | Hostnames the distribution serves (apex and `www`); each needs A and AAAA alias records. |
| <a name="output_distribution_arn"></a> [distribution\_arn](#output\_distribution\_arn) | ARN of the CloudFront distribution. Pass to `nextjs-lambda` (and `nextjs-assets` when serving static assets from S3) as `cloudfront_distribution_arn`. |
| <a name="output_distribution_domain_name"></a> [distribution\_domain\_name](#output\_distribution\_domain\_name) | CloudFront domain name of the distribution (e.g. `d111111abcdef8.cloudfront.net`), the target of Route 53 alias records. |
| <a name="output_distribution_hosted_zone_id"></a> [distribution\_hosted\_zone\_id](#output\_distribution\_hosted\_zone\_id) | Route 53 hosted zone ID of the distribution, for alias records. |
| <a name="output_distribution_id"></a> [distribution\_id](#output\_distribution\_id) | ID of the CloudFront distribution (for cache invalidations). |
<!-- END_TF_DOCS -->
