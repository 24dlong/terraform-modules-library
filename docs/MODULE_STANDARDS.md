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
  "hashicorp/aws", version = "< 7.0.0" } }` (compatible with AWS provider
  v5 and v6). Raising the ceiling past a new major is a breaking (MAJOR)
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
      version = "< 7.0.0"
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
  source = "git::https://github.com/24dlong/terraform-modules-library.git//modules/nextjs-lambda?ref=v1.2.0"
  # ...
}
```

A floating major-version tag (e.g. `v1`) is also maintained (see
[Release process](#release-process)) purely as a convenience for quick manual
testing; production consumers must always pin the exact `MAJOR.MINOR.PATCH`
tag so upgrades are explicit and reviewed.

## Account-level singletons

Some AWS resources are unique per account rather than per module instance —
for example, an account may only have **one** `token.actions.githubusercontent.com`
IAM OIDC provider per provider URL. Modules that create this kind of resource
(e.g. `github-oidc`) must accept a `create_<resource>` boolean input (default
`true`) plus a corresponding `<resource>_arn` input (default `null`) so every
consumer after the first in a given account can pass `create_<resource> =
false` and reference the existing resource instead of failing on a duplicate-
resource error at apply time.

## Provider aliases / region remapping

Most modules inherit the caller's default `aws` provider. When a module's
resources **must** live in a fixed region (notably ACM certificates for
CloudFront, which require `us-east-1`), prefer remapping the module's
default `aws` provider to a caller-configured alias rather than declaring
`configuration_aliases` inside the module. Remapping keeps
`terraform validate` working when the module directory is treated as a root
(CI / pre-commit); `configuration_aliases` currently break that path.

Example (`route53-acm` — entire module runs in `us-east-1`):

```hcl
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "route53_acm" {
  source = "..."
  providers = {
    aws = aws.us_east_1
  }
  # ...
}
```

Do not hard-code a `provider "aws"` block inside a module; only document the
required remapping (or `configuration_aliases`, if a future module truly
needs two regions in one call) and let the root configure
regions/credentials.

## Tagging and naming

- Resource names use the pattern `${var.name_prefix}-<resource>` and every
  resource sets a common `tags` variable merged with any module-specific tags.
  Domain-keyed modules (e.g. `route53-acm`, which adopts a zone by DNS name)
  may omit `name_prefix` and document that departure in the module README.
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
  -->` markers. Files under `examples/` are excluded from this hook and must
  not contain a generated `README.md`; document example usage, if needed, in
  the owning module's `README.md` instead.

The exact `terraform`, `terraform-docs`, `checkov`, and `pre-commit` versions
are pinned once in [`.tool-versions`](../.tool-versions) at the repository
root and installed via `mise` by both `make setup-env` and the pull-request
workflow, so local and CI runs always resolve identical tool versions.

## Provider lock files

Every module and example that has been `terraform init`'d must commit its
`.terraform.lock.hcl`. That lock file must include provider package hashes
for **all** platforms used locally and in CI:

- `linux_amd64` (GitHub Actions `ubuntu-latest`)
- `darwin_amd64` / `darwin_arm64` (local macOS)

Plain `terraform init` only records the current host platform. Committing a
single-platform lock file makes the `terraform_validate` pre-commit hook
pass locally but fail on Linux CI with `files were modified by this hook`
(CI's `terraform init` appends the missing platform hash).

After adding a new module/example, or after changing a provider version
constraint, regenerate locks with:

```sh
make providers-lock
# or, scoped:
make providers-lock DIRS="modules/<name> examples/<name>"
```

Then commit the updated `.terraform.lock.hcl` files. A lock file is
complete when it has multiple `h1:` entries (one per platform), not a
single host-only hash.

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
