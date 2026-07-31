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
