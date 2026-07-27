# Module and Repository Standards

This document defines the structural and versioning conventions every module in
this repository must follow. It exists so new modules (state, identity, domain,
Lambda, assets, CloudFront, and any future module) are consistent, easy to
review, and safe to compose from the shared-foundation and application
Cookiecutter repositories.

## Directory layout

Each module lives under `modules/<module-name>/` and contains:

```text
modules/<module-name>/
├── main.tf          # Resources
├── variables.tf     # Inputs, each with a description and type
├── outputs.tf       # Outputs consumed by other modules/roots
├── versions.tf       # Terraform + provider version constraints (see below)
└── README.md        # terraform-docs generated usage/inputs/outputs table
```

Larger modules may split `main.tf` into topic files (e.g. `iam.tf`, `logging.tf`),
but must keep `variables.tf`, `outputs.tf`, and `versions.tf` as the single
source of truth for their respective concerns.

Every module must ship at least one working example under
`examples/<module-name>/`, referencing the module by relative path
(`source = "../../modules/<module-name>"`) so examples validate against the
in-repo module during CI, not a tagged release.

## Versioning policy

- **Terraform core:** modules declare `required_version = ">= 1.9, < 2.0.0"`
  (raise the floor only for a feature all modules need; never remove the
  ceiling without a major module version bump).
- **AWS provider:** modules declare `required_providers { aws = { source =
  "hashicorp/aws", version = ">= 5.0, < 6.0.0" } }` unless a specific module
  requires a newer major version, in which case that is a breaking (MAJOR)
  change for that module.
- Modules must not pin an exact provider version; only a compatible range.
  Root configurations (shared-foundation, generated application infra) are
  responsible for locking exact provider versions via their own lockfile.

Standard `versions.tf` template:

```hcl
terraform {
  required_version = ">= 1.9, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0.0"
    }
  }
}
```

## Consumption / module references

Consumers (the shared-foundation repository and the generated application
Cookiecutter output) reference modules with a Git tag and subdirectory source
reference, pinned to an exact semantic version tag — never a floating branch,
floating major tag, or local relative path:

```hcl
module "nextjs_lambda" {
  source = "git::https://github.com/24dlong/terraform-aws-modules.git//modules/nextjs-lambda?ref=v1.2.0"
  # ...
}
```

A floating major-version tag (e.g. `v1`) is also maintained (see
[Release process](#release-process)) purely as a convenience for quick manual
testing; production consumers must always pin the exact `MAJOR.MINOR.PATCH`
tag so upgrades are explicit and reviewed.

## Tagging and naming

- Resource names use the pattern `${var.name_prefix}-<resource>` and every
  resource sets a common `tags` variable merged with any module-specific tags.
- No module may hard-code an AWS account ID, region, domain name, or
  application-specific value; those are always inputs.

## CI validation

Every module and example must pass, via `make lint` / the pull-request
workflow:

- `terraform fmt -recursive -check -diff`
- `terraform init -backend=false` + `terraform validate` (per module and per
  example, independently)
- `checkov` static analysis
- `terraform-docs` — module `README.md` files are generated/verified, not
  hand maintained, between the `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS
  -->` markers.

## Release process

This repository uses [Conventional Commits](https://www.conventionalcommits.org)
and [Commitizen](https://commitizen-tools.github.io/commitizen/) to determine
semantic version bumps automatically on merge to `main`:

- `fix:` → PATCH
- `feat:` → MINOR
- `BREAKING CHANGE:` footer, or `!` after the type/scope → MAJOR
- `chore:`, `docs:`, `build:`, `style:`, `refactor:`, `perf:`, `test:` → PATCH

On every push to `main` (that isn't itself a version bump commit), the merge
workflow bumps the version, updates `CHANGELOG.md`, creates the
`MAJOR.MINOR.PATCH` tag, and moves the floating `vMAJOR` tag to point at it.
Because a single tag applies to the entire repository, an unrelated change to
one module still increments the shared version — this is an accepted
trade-off for keeping the release process simple with one repository hosting
multiple modules.
