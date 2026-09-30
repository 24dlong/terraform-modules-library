# Least-privilege execution role: write to this function's log group only.
# Anything else (Secrets Manager reads, extra managed policies) is additive
# via inputs.

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name_prefix}-web-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-web-lambda"
  })
}

data "aws_iam_policy_document" "execution" {
  statement {
    sid    = "WriteFunctionLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["${aws_cloudwatch_log_group.this.arn}:*"]
  }

  dynamic "statement" {
    for_each = length(var.secret_arns) > 0 ? [1] : []

    content {
      sid       = "ReadRuntimeSecrets"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = var.secret_arns
    }
  }
}

resource "aws_iam_role_policy" "execution" {
  name   = "execution"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.execution.json
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = { for index, arn in var.additional_policy_arns : tostring(index) => arn }

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
