# github-oidc

GitHub Actions OIDC identity provider plus a least-privilege IAM role scoped
to a single GitHub repository (and optionally a single branch). GitHub
Actions exchanges its OIDC token for short-lived AWS credentials via
`sts:AssumeRoleWithWebIdentity` — no long-lived AWS access keys are created
or required anywhere.

Security notes:

- The trust policy's `token.actions.githubusercontent.com:sub` condition
  restricts assumption to `repo:<org>/<repo>:ref:refs/heads/<branch>` by
  default. Set `allow_all_branches = true` only when broader access across
  every branch/ref in the repository is explicitly required; the role
  remains scoped to a single repository either way.
- This module grants **no permissions** to the role itself. Callers attach
  their own least-privilege permissions via `managed_policy_arns` and/or
  `inline_policy_json`.
- AWS accounts may only have one `token.actions.githubusercontent.com` OIDC
  provider per account. Set `create_oidc_provider = false` and pass the
  existing provider's ARN via `github_oidc_provider_arn` for every consumer
  after the first in a given account.

See [`docs/MODULE_STANDARDS.md`](../../docs/MODULE_STANDARDS.md) for this
repository's versioning and consumption conventions. See
[`examples/github-oidc`](../../examples/github-oidc) for a runnable example.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allow_all_branches"></a> [allow\_all\_branches](#input\_allow\_all\_branches) | Whether to trust every branch/ref in the given repository (`repo:<org>/<br/><repo>:*`) instead of restricting to a single branch. Must only be set to<br/>`true` when broader access across branches is explicitly required; the<br/>role is still scoped to a single repository either way. | `bool` | `false` | no |
| <a name="input_create_oidc_provider"></a> [create\_oidc\_provider](#input\_create\_oidc\_provider) | Whether to create the `token.actions.githubusercontent.com` IAM OIDC<br/>identity provider. AWS accounts may only have one OIDC provider per<br/>provider URL, so only the first consumer in a given account should set<br/>this to `true`; every subsequent consumer must set this to `false` and<br/>supply the existing provider's ARN via `github_oidc_provider_arn`. | `bool` | `true` | no |
| <a name="input_github_branch"></a> [github\_branch](#input\_github\_branch) | Branch trusted to assume this role. Ignored when allow\_all\_branches is true. | `string` | `"main"` | no |
| <a name="input_github_oidc_provider_arn"></a> [github\_oidc\_provider\_arn](#input\_github\_oidc\_provider\_arn) | ARN of an existing `token.actions.githubusercontent.com` IAM OIDC<br/>provider. Required (must not be `null`) when `create_oidc_provider` is<br/>`false`; ignored when `create_oidc_provider` is `true`. | `string` | `null` | no |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | GitHub organization or user that owns the repository trusted to assume this role (e.g. "24dlong"). | `string` | n/a | yes |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | GitHub repository name (without the owner) trusted to assume this role. | `string` | n/a | yes |
| <a name="input_inline_policy_json"></a> [inline\_policy\_json](#input\_inline\_policy\_json) | An IAM policy document (JSON) to attach to the role as an inline policy.<br/>When omitted (`null`), no inline policy is attached. | `string` | `null` | no |
| <a name="input_managed_policy_arns"></a> [managed\_policy\_arns](#input\_managed\_policy\_arns) | List of AWS managed or customer-managed IAM policy ARNs to attach to the<br/>role. This module intentionally grants no permissions itself; callers<br/>attach their own least-privilege permissions here and/or via<br/>inline\_policy\_json. | `list(string)` | `[]` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used to name the IAM role created by this module (e.g. "myapp-prod"). | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags merged into every resource created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | ARN of the token.actions.githubusercontent.com OIDC provider used by this module (created or pre-existing). |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the IAM role GitHub Actions assumes via OIDC. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the IAM role GitHub Actions assumes via OIDC. |
<!-- END_TF_DOCS -->
