# nextjs-assets

Private, encrypted, versioned S3 bucket for Next.js static assets
(`/_next/static/*` and selected public assets). CloudFront Origin Access
Control (OAC) is owned by the `nextjs-cloudfront` module; this module only
optionally grants `s3:GetObject` to a known distribution ARN.

Security defaults:

- Public access is fully blocked; object ownership is `BucketOwnerEnforced`
  (no ACLs).
- Server-side encryption is enabled by default (SSE-S3, or SSE-KMS if
  `kms_key_arn` is supplied).
- Bucket versioning is enabled so a bad asset deploy can be rolled back.
- A bucket policy always denies any request made without TLS
  (`aws:SecureTransport = false`).
- When `cloudfront_distribution_arn` is set, an additional statement allows
  `cloudfront.amazonaws.com` to `s3:GetObject` only when
  `AWS:SourceArn` matches that distribution (OAC). When omitted, the bucket
  is fully private — including from CloudFront — so the module can be
  deployed before a distribution exists.
- Noncurrent object versions expire after
  `noncurrent_version_expiration_days` (default `90`); set to `0` to retain
  all versions indefinitely.

See [`docs/MODULE_STANDARDS.md`](../../docs/MODULE_STANDARDS.md) for this
repository's versioning and consumption conventions. See
[`examples/nextjs-assets`](../../examples/nextjs-assets) for a runnable
example.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | < 7.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.62.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_s3_bucket.assets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.assets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.assets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.assets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.assets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.assets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.assets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.assets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_policy_document.assets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_log_bucket"></a> [access\_log\_bucket](#input\_access\_log\_bucket) | Name of an existing S3 bucket to receive server access logs for the assets<br/>bucket. When omitted (`null`), access logging is not configured; provide<br/>a dedicated logging bucket to satisfy access-logging requirements. | `string` | `null` | no |
| <a name="input_access_log_prefix"></a> [access\_log\_prefix](#input\_access\_log\_prefix) | Key prefix applied to access log objects delivered to `access_log_bucket`. | `string` | `"nextjs-assets/"` | no |
| <a name="input_cloudfront_distribution_arn"></a> [cloudfront\_distribution\_arn](#input\_cloudfront\_distribution\_arn) | ARN of the CloudFront distribution allowed to read objects from this<br/>bucket via Origin Access Control (OAC). When omitted (`null`), the<br/>CloudFront GetObject statement is not created and the bucket stays<br/>fully private (no CloudFront access). Pass the distribution ARN in a<br/>later apply once the distribution exists. | `string` | `null` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Whether to allow Terraform to destroy the assets bucket even if it still<br/>contains objects. Must remain `false` in any environment that holds real<br/>application assets; only intended for disposable test/example deployments. | `bool` | `false` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of a customer-managed KMS key used to encrypt the assets bucket. When<br/>omitted (`null`), the bucket uses the default Amazon S3-managed encryption<br/>key (SSE-S3). | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used to name the assets bucket (e.g. "myapp-prod"). The bucket is named "<name\_prefix>-assets". | `string` | n/a | yes |
| <a name="input_noncurrent_version_expiration_days"></a> [noncurrent\_version\_expiration\_days](#input\_noncurrent\_version\_expiration\_days) | Number of days to retain noncurrent (superseded) object versions before<br/>they are permanently expired. Set to `0` to disable expiration and retain<br/>all historical versions indefinitely. | `number` | `90` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags merged into every resource created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the Next.js static assets S3 bucket. |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | Name of the Next.js static assets S3 bucket. |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | Regional domain name of the assets bucket (for CloudFront S3 origin config). |
<!-- END_TF_DOCS -->
