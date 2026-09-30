# nextjs-lambda

ECR repository plus a Lambda container function running a Next.js
standalone server behind the
[AWS Lambda Web Adapter](https://github.com/aws/aws-lambda-web-adapter),
exposed through an `AWS_IAM`-authenticated Function URL. CloudFront (the
`nextjs-cloudfront` module) is the intended public edge; this module only
optionally grants a known distribution permission to invoke the URL.

Security defaults:

- The Function URL uses `AWS_IAM` auth. Nothing is publicly invokable.
- The execution role can only write to this function's log group. Secrets
  Manager reads (`secret_arns`) and extra managed policies
  (`additional_policy_arns`) are opt-in.
- ECR tags are immutable and images are scanned on push.
- The log group has bounded retention (`log_retention_days`, default `14`).
- When `cloudfront_distribution_arn` is set, `cloudfront.amazonaws.com` is
  granted both `lambda:InvokeFunctionUrl` and `lambda:InvokeFunction`,
  scoped by `source_arn` to that distribution. Function URLs created after
  October 2025 require both actions. The second permission does not set
  `invoked_via_function_url` because that argument needs AWS provider
  `>= 6.28`, and this repository's modules stay compatible with v5; the
  CloudFront service principal can only reach the function through the
  origin URL, so `source_arn` alone is the documented AWS scoping.

See [`docs/MODULE_STANDARDS.md`](../../docs/MODULE_STANDARDS.md) for this
repository's versioning and consumption conventions. See
[`examples/nextjs-lambda`](../../examples/nextjs-lambda) for a runnable
example.

## Container image requirements

This module does not build images. The application repository publishes
them to `ecr_repository_url` and they must:

- Include the Lambda Web Adapter as an extension, e.g.
  `COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:<version> /lambda-adapter /opt/extensions/lambda-adapter`.
  No `AWS_LAMBDA_EXEC_WRAPPER` is needed; that is only for zip/layer
  functions.
- Serve HTTP on `AWS_LWA_PORT` (falls back to `PORT`, default `8080`) and
  answer the readiness check (`AWS_LWA_READINESS_CHECK_PATH`, default `/`).
  Set these through `environment_variables` if the image differs.
- Be built for the function's `architecture` (`linux/arm64` by default).
- Be pushed under a new version tag for every release. Tags are immutable,
  so re-pushing an existing tag fails.

The lifecycle policy keeps the `image_retention_count` most recent images
(default `20`). Lambda needs the image it is running to stay in ECR, so keep
that above the number of releases between deploys you might roll back to.

## Two-phase apply (`image_tag`)

Lambda cannot be created before its image exists, and the image cannot be
pushed before the repository exists:

1. Apply with `image_tag = null`. Creates the ECR repository, execution role,
   and log group only.
2. The application repository pushes `<ecr_repository_url>:<version>`.
3. Apply with `image_tag = "<version>"`. Creates the function and Function
   URL. Later deploys and rollbacks change `image_tag` only.

Set `image_tag` in the environment's tfvars so it shows up in the plan.

## CloudFront wiring (second pass)

`nextjs-cloudfront` needs this module's `function_url`, and the CloudFront
permissions here need that distribution's ARN. Apply without
`cloudfront_distribution_arn` first, then pass the distribution's `arn`
output in a later apply (same pattern as `nextjs-assets`).

## Manual verification

Using the example in `us-east-2` with the placeholder image in
[`examples/nextjs-lambda/placeholder`](../../examples/nextjs-lambda/placeholder):

```sh
cd examples/nextjs-lambda
terraform init && terraform apply
REPO=$(terraform output -raw ecr_repository_url)

aws ecr get-login-password --region us-east-2 \
  | docker login --username AWS --password-stdin "${REPO%%/*}"
docker build --platform linux/arm64 --provenance=false -t "$REPO:0.0.1" placeholder
docker push "$REPO:0.0.1"

terraform apply -var image_tag=0.0.1
awscurl --service lambda --region us-east-2 "$(terraform output -raw function_url)"

terraform destroy -var image_tag=0.0.1
```

`awscurl` signs the request with your local credentials, which need
`lambda:InvokeFunctionUrl` and `lambda:InvokeFunction` on the function. An
unsigned `curl` against the URL returns `403`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | < 7.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.66.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function_url.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_url) | resource |
| [aws_lambda_permission.cloudfront_invoke_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.cloudfront_invoke_function_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_policy_arns"></a> [additional\_policy\_arns](#input\_additional\_policy\_arns) | ARNs of additional IAM managed policies to attach to the Lambda execution role. | `list(string)` | `[]` | no |
| <a name="input_architecture"></a> [architecture](#input\_architecture) | Instruction set architecture of the Lambda function. Must match the pushed image's platform. | `string` | `"arm64"` | no |
| <a name="input_cloudfront_distribution_arn"></a> [cloudfront\_distribution\_arn](#input\_cloudfront\_distribution\_arn) | ARN of the CloudFront distribution allowed to invoke the Function URL via<br/>Origin Access Control (OAC). When omitted (`null`), no CloudFront<br/>permissions are created and the Function URL is only reachable with<br/>signed IAM requests from principals in this account. Pass the<br/>distribution ARN in a later apply once the distribution exists. | `string` | `null` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Non-secret environment variables for the Lambda function (e.g.<br/>`AWS_LWA_PORT`, `AWS_LWA_READINESS_CHECK_PATH`, `NODE_ENV`). Values are<br/>stored in Terraform state and visible in the Lambda console; deliver<br/>secrets through Secrets Manager (`secret_arns`) instead. | `map(string)` | `{}` | no |
| <a name="input_force_delete"></a> [force\_delete](#input\_force\_delete) | Whether to allow Terraform to delete the ECR repository even if it still<br/>contains images. Must remain `false` in any environment that holds real<br/>application images; only intended for disposable test/example deployments. | `bool` | `false` | no |
| <a name="input_image_retention_count"></a> [image\_retention\_count](#input\_image\_retention\_count) | Number of most recent tagged images kept in the ECR repository. Older tagged images expire, so keep this above the number of releases you may need to roll back to. | `number` | `20` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Tag of the container image in this module's ECR repository to run (e.g.<br/>the application release version `"1.4.0"`). The image URI is built as<br/>`<ecr_repository_url>:<image_tag>`. When omitted (`null`), only the ECR<br/>repository, IAM role, and log group are created; the Lambda function,<br/>Function URL, and CloudFront permissions are created once a tag is set<br/>and that image has been pushed. | `string` | `null` | no |
| <a name="input_invoke_mode"></a> [invoke\_mode](#input\_invoke\_mode) | Function URL invoke mode. `BUFFERED` returns the full response at once;<br/>`RESPONSE_STREAM` streams it and requires the image to run the Lambda Web<br/>Adapter with `AWS_LWA_INVOKE_MODE=response_stream`. | `string` | `"BUFFERED"` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of a customer-managed KMS key used to encrypt the ECR repository, the<br/>CloudWatch log group, and the function's environment variables. The key<br/>policy must allow the CloudWatch Logs service principal for this region.<br/>When omitted (`null`), AWS-managed encryption is used for all three. | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain the Lambda function's CloudWatch logs. Must be a value CloudWatch Logs accepts; `0` (never expire) is intentionally not allowed. | `number` | `14` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Amount of memory in MB available to the Lambda function. | `number` | `1024` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used to name every resource (e.g. "myapp-prod"). The ECR repository is "<name\_prefix>-web" and the Lambda function is "<name\_prefix>-web". | `string` | n/a | yes |
| <a name="input_reserved_concurrent_executions"></a> [reserved\_concurrent\_executions](#input\_reserved\_concurrent\_executions) | Reserved concurrency for the Lambda function. `null` leaves the function on the account's unreserved concurrency pool. | `number` | `null` | no |
| <a name="input_secret_arns"></a> [secret\_arns](#input\_secret\_arns) | ARNs of Secrets Manager secrets the function may read with<br/>`secretsmanager:GetSecretValue` at startup. Secrets encrypted with a<br/>customer-managed KMS key also need `kms:Decrypt` on that key, granted via<br/>`additional_policy_arns` or the key policy. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags merged into every resource created by this module. | `map(string)` | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Lambda function timeout in seconds. | `number` | `15` | no |
| <a name="input_untagged_image_expiration_days"></a> [untagged\_image\_expiration\_days](#input\_untagged\_image\_expiration\_days) | Number of days after push that untagged images (e.g. intermediate build layers) are expired from the ECR repository. | `number` | `7` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | ARN of the ECR repository (for granting the application repo's CI push access). |
| <a name="output_ecr_repository_name"></a> [ecr\_repository\_name](#output\_ecr\_repository\_name) | Name of the ECR repository. |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | URL of the ECR repository the application publishes images to (`<account>.dkr.ecr.<region>.amazonaws.com/<name>`). |
| <a name="output_execution_role_arn"></a> [execution\_role\_arn](#output\_execution\_role\_arn) | ARN of the Lambda execution role. |
| <a name="output_execution_role_name"></a> [execution\_role\_name](#output\_execution\_role\_name) | Name of the Lambda execution role (for attaching extra inline policies outside this module). |
| <a name="output_function_arn"></a> [function\_arn](#output\_function\_arn) | ARN of the Lambda function. `null` until `image_tag` is set. |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | Name of the Lambda function. `null` until `image_tag` is set. |
| <a name="output_function_url"></a> [function\_url](#output\_function\_url) | AWS\_IAM-authenticated Function URL (the CloudFront Lambda origin). `null` until `image_tag` is set. |
| <a name="output_image_uri"></a> [image\_uri](#output\_image\_uri) | Image URI the function runs (`<ecr_repository_url>:<image_tag>`). `null` until `image_tag` is set. |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | Name of the Lambda function's CloudWatch log group. |
<!-- END_TF_DOCS -->
