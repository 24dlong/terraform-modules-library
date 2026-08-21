variable "name_prefix" {
  description = "Prefix used to name the IAM role created by this module (e.g. \"myapp-prod\")."
  type        = string
}

variable "tags" {
  description = "Common tags merged into every resource created by this module."
  type        = map(string)
  default     = {}
}

variable "create_oidc_provider" {
  description = <<-EOT
    Whether to create the `token.actions.githubusercontent.com` IAM OIDC
    identity provider. AWS accounts may only have one OIDC provider per
    provider URL, so only the first consumer in a given account should set
    this to `true`; every subsequent consumer must set this to `false` and
    supply the existing provider's ARN via `github_oidc_provider_arn`.
  EOT
  type        = bool
  default     = true
}

variable "github_oidc_provider_arn" {
  description = <<-EOT
    ARN of an existing `token.actions.githubusercontent.com` IAM OIDC
    provider. Required (must not be `null`) when `create_oidc_provider` is
    `false`; ignored when `create_oidc_provider` is `true`.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.create_oidc_provider || var.github_oidc_provider_arn != null
    error_message = "github_oidc_provider_arn must be set when create_oidc_provider is false."
  }
}

variable "github_org" {
  description = "GitHub organization or user that owns the repository trusted to assume this role (e.g. \"24dlong\")."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without the owner) trusted to assume this role."
  type        = string
}

variable "github_branch" {
  description = <<-EOT
    Branch trusted to assume this role. Ignored when allow_all_branches is
    true or github_environment is set.
  EOT
  type        = string
  default     = "main"
}

variable "github_environment" {
  description = <<-EOT
    GitHub Environment name trusted to assume this role
    (`repo:<org>/<repo>:environment:<name>`). Set this when the assuming
    job uses `environment:` — GitHub then puts the environment in `sub`
    instead of the branch ref, so a branch-only trust policy will not
    match. Ignored when allow_all_branches is true. Restrict which
    branches can use the Environment with GitHub Environment deployment
    branch rules, not this IAM condition.
  EOT
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.github_environment == null || length(trimspace(var.github_environment)) > 0
    error_message = "github_environment must be a non-empty GitHub Environment name when set."
  }
}

variable "allow_all_branches" {
  description = <<-EOT
    Whether to trust every branch/ref/environment in the given repository
    (`repo:<org>/<repo>:*`) instead of restricting to a single branch or
    GitHub Environment. Must only be set to `true` when broader access
    across branches is explicitly required; the role is still scoped to a
    single repository either way. Takes precedence over github_branch and
    github_environment.
  EOT
  type        = bool
  default     = false
}

variable "managed_policy_arns" {
  description = <<-EOT
    List of AWS managed or customer-managed IAM policy ARNs to attach to the
    role. This module intentionally grants no permissions itself; callers
    attach their own least-privilege permissions here and/or via
    inline_policy_json.
  EOT
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = <<-EOT
    An IAM policy document (JSON) to attach to the role as an inline policy.
    When omitted (`null`), no inline policy is attached.
  EOT
  type        = string
  default     = null
}
