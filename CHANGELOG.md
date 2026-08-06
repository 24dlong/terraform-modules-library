## 0.3.3 (2026-08-06)


- chore(deps): update minor-updates (#14)
- Co-authored-by: 24dlong-renovate[bot] <286791535+24dlong-renovate[bot]@users.noreply.github.com>

## 0.3.2 (2026-08-05)


- chore(deps): update minor-updates (#10)
- * chore(deps): update minor-updates
- * ci: explicitly set top-level permissions
- * fix: pin python version
- ---------
- Co-authored-by: 24dlong-renovate[bot] <286791535+24dlong-renovate[bot]@users.noreply.github.com>
Co-authored-by: Daniel Long <24.daniel.long@gmail.com>

## 0.3.1 (2026-08-04)


- chore(deps): update terraform aws to v6 (#12)
- Co-authored-by: 24dlong-renovate[bot] <286791535+24dlong-renovate[bot]@users.noreply.github.com>

## 0.3.0 (2026-07-31)


- feat(github-oidc): add GitHub Actions OIDC provider and deploy role module (#9)
- Adds a reusable module creating the token.actions.githubusercontent.com
OIDC provider plus a least-privilege IAM role scoped to a single GitHub
repository (and optionally branch) via the sub claim. Supports reusing an
existing OIDC provider (create_oidc_provider = false) since AWS accounts
allow only one provider per URL. Grants no permissions itself; callers
attach their own via managed_policy_arns / inline_policy_json.
- Includes a runnable example, README updates marking the module implemented,
and a new MODULE_STANDARDS.md section documenting the account-level-
singleton input pattern for future modules.

## 0.2.1 (2026-07-31)


- chore(deps): update pre-commit hook pre-commit/pre-commit-hooks to v6 (#11)
- Co-authored-by: 24dlong-renovate[bot] <286791535+24dlong-renovate[bot]@users.noreply.github.com>
- ci: manages tooling versions using mise (#8)

## 0.2.0 (2026-07-30)


- feat(terraform-state): add Terraform remote state module (#4)
- * feat(terraform-state): add Terraform remote state module
- Add the terraform-state module: a private, encrypted, versioned S3
bucket for Terraform remote state with S3 native locking support (no
DynamoDB table required). Includes public access block, TLS-only
bucket policy, optional KMS encryption, optional access logging,
lifecycle rules (noncurrent-version expiration and incomplete
multipart upload abort), a runnable example, terraform-docs generated
README, and a repository-level Checkov config skipping two checks
(event notifications, cross-region replication) that don't apply to
this repository's internal building-block modules. Point the
terraform_checkov pre-commit hook at that config via the
__GIT_WORKING_DIR__ placeholder, and stop tracking generated
.terraform.lock.hcl files for modules/examples.
- Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
- * fix(docs): exclude examples directory from terraform-docs generation
- Add an exclude regex to the terraform_docs pre-commit hook so example
directories no longer get an auto-generated README.md. Remove the
generated examples/terraform-state/README.md and document the
exclusion in docs/MODULE_STANDARDS.md.
- Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
- * bump: bump terraform docs version
- ---------
- Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
- ci: install terraform docs in pull_request workflow (#7)

## 0.1.1 (2026-07-30)


- chore(deps): update actions/setup-python action to v7 (#5)
- Co-authored-by: 24dlong-renovate[bot] <286791535+24dlong-renovate[bot]@users.noreply.github.com>

## 0.1.0 (2026-07-29)


- feat: scaffold repository
- Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
