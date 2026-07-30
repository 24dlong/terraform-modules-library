# GitHub Actions OIDC identity provider + a least-privilege, repo/branch-
# scoped IAM deployment role. No long-lived AWS access keys are created or
# required; GitHub Actions authenticates by exchanging its OIDC token for
# short-lived credentials via sts:AssumeRoleWithWebIdentity.

locals {
  # AWS accounts may only have a single OIDC provider per URL. When this
  # module doesn't own the provider (create_oidc_provider = false), consumers
  # must supply the existing provider's ARN.
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.github_oidc_provider_arn

  github_subject = var.allow_all_branches ? "repo:${var.github_org}/${var.github_repo}:*" : "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-github-oidc-provider"
  })
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_subject]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name_prefix}-github-oidc-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-github-oidc-role"
  })
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy_json != null ? 1 : 0

  name   = "${var.name_prefix}-github-oidc-inline"
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}
