# route53-acm

Adopts an existing public Route 53 hosted zone (data source only — never
creates or destroys the zone) and issues a DNS-validated ACM certificate in
`us-east-1` covering the apex domain plus a wildcard SAN
(`*.<domain_name>`). CloudFront requires certificates in `us-east-1`
regardless of the application's compute region.

## Intended ownership

Call this module from **per-application shared infrastructure** (one
Terraform root / state per app), not from a multi-app platform root. Each
application's certificate should live in that application's own state so
`www.app1.example` and `www.app2.example` are never coupled in one apply.

Within one application, frontend and backend services consume
`certificate_arn` / `zone_id` via remote state from that app-shared root.

## Provider remapping (required)

ACM-for-CloudFront must live in `us-east-1`. This module uses the caller's
default `aws` provider for both ACM and Route 53 validation records (Route 53
is global). Callers must remap that default to a `us-east-1` configuration:

```hcl
provider "aws" {
  region = "us-east-2"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "route53_acm" {
  source = "git::https://github.com/24dlong/terraform-modules-library.git//modules/route53-acm?ref=0.6.0"

  providers = {
    aws = aws.us_east_1
  }

  domain_name = "example.com"
  tags = {
    Project = "example-app"
  }
}
```

Do not call this module with a default-region `us-east-2` provider — the
certificate would be created in the wrong region for CloudFront.

## Naming

This module is **domain-keyed** (`domain_name`), not `name_prefix`-keyed.
The hosted zone already exists under its DNS name; the certificate's `Name`
tag is set to `var.domain_name`. That is an intentional departure from the
`${name_prefix}-<resource>` pattern used by other modules in this library.

## Testing

`terraform fmt`, `terraform validate`, and Checkov run in CI without AWS
credentials and without a real hosted zone. A full `terraform apply` of the
example (or any consumer) requires:

1. An existing public Route 53 hosted zone for `domain_name`
2. Registrar nameserver delegation already pointing at that zone (otherwise
   ACM DNS validation will not reach `ISSUED`)
3. AWS credentials with Route 53 change permissions on the zone and ACM
   permissions in `us-east-1`

Isolated CI cannot exercise the apply path; end-to-end validation belongs to
the consuming application-shared-infra root.

See [`docs/MODULE_STANDARDS.md`](../../docs/MODULE_STANDARDS.md) for this
repository's versioning and consumption conventions. See
[`examples/route53-acm`](../../examples/route53-acm) for a validate-only
example layout.

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
| [aws_acm_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_route53_record.validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Apex domain name of an existing public Route 53 hosted zone (e.g.<br/>"example.com"). The zone is looked up via data source and never created<br/>or destroyed by this module. The ACM certificate covers this name plus<br/>a wildcard SAN (`*.<domain_name>`). | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags merged into every resource created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_certificate_arn"></a> [certificate\_arn](#output\_certificate\_arn) | ARN of the DNS-validated ACM certificate in us-east-1 (ISSUED). |
| <a name="output_name_servers"></a> [name\_servers](#output\_name\_servers) | Name servers for the adopted hosted zone (confirm registrar delegation). |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | ID of the adopted public Route 53 hosted zone. |
| <a name="output_zone_name"></a> [zone\_name](#output\_zone\_name) | Name of the adopted public Route 53 hosted zone. |
<!-- END_TF_DOCS -->
