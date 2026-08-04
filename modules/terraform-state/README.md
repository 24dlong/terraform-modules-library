# terraform-state

Private, encrypted, versioned S3 bucket for storing Terraform remote state,
with support for [S3 native state locking](https://developer.hashicorp.com/terraform/language/backend/s3#state-locking)
(`use_lockfile = true` in a consumer's `backend "s3"` block) — no DynamoDB
lock table is created or required.

Security defaults:

- Public access is fully blocked (ACLs, policies, and cross-account access).
- Server-side encryption is enabled by default (SSE-S3, or SSE-KMS if
  `kms_key_arn` is supplied).
- Bucket versioning is enabled so that prior state files can be recovered.
- A bucket policy denies any request made without TLS
  (`aws:SecureTransport = false`).
- Noncurrent (superseded) state versions are expired after
  `noncurrent_version_expiration_days` (default `90`) to bound storage cost;
  set to `0` to retain all versions indefinitely.

See [`docs/MODULE_STANDARDS.md`](../../docs/MODULE_STANDARDS.md) for this
repository's versioning and consumption conventions. See
[`examples/terraform-state`](../../examples/terraform-state) for a runnable
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.57.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_s3_bucket.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_policy.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_policy_document.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_log_bucket"></a> [access\_log\_bucket](#input\_access\_log\_bucket) | Name of an existing S3 bucket to receive server access logs for the state<br/>bucket. When omitted (`null`), access logging is not configured; provide<br/>a dedicated logging bucket to satisfy access-logging requirements. | `string` | `null` | no |
| <a name="input_access_log_prefix"></a> [access\_log\_prefix](#input\_access\_log\_prefix) | Key prefix applied to access log objects delivered to `access_log_bucket`. | `string` | `"terraform-state/"` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Whether to allow Terraform to destroy the state bucket even if it still<br/>contains objects (including prior state file versions). Must remain<br/>`false` in any environment that holds real Terraform state; only intended<br/>for disposable test/example deployments. | `bool` | `false` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of a customer-managed KMS key used to encrypt the state bucket. When<br/>omitted (`null`), the bucket uses the default Amazon S3-managed encryption<br/>key (SSE-S3). | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used to name the Terraform state bucket (e.g. "myapp-prod"). | `string` | n/a | yes |
| <a name="input_noncurrent_version_expiration_days"></a> [noncurrent\_version\_expiration\_days](#input\_noncurrent\_version\_expiration\_days) | Number of days to retain noncurrent (superseded) state file versions<br/>before they are permanently expired. Set to `0` to disable expiration and<br/>retain all historical versions indefinitely. | `number` | `90` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags merged into every resource created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the Terraform state S3 bucket. |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | Name of the Terraform state S3 bucket. |
| <a name="output_bucket_region"></a> [bucket\_region](#output\_bucket\_region) | AWS region the Terraform state S3 bucket was created in. |
<!-- END_TF_DOCS -->
