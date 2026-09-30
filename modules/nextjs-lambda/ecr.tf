# Private ECR repository the application repo publishes release images to.
# Tags are immutable so a version tag always refers to the same image, which
# keeps `image_tag` deploys and rollbacks reproducible.

locals {
  # arn:<partition>:ecr:<region>:<account>:repository/<name>
  ecr_arn_parts       = split(":", aws_ecr_repository.this.arn)
  function_arn_prefix = "arn:${local.ecr_arn_parts[1]}:lambda:${local.ecr_arn_parts[3]}:${local.ecr_arn_parts[4]}:function:${local.function_name}"
}

resource "aws_ecr_repository" "this" {
  #checkov:skip=CKV_AWS_136:KMS encryption is opt-in via kms_key_arn; AES256 is the default for this internal image repository.
  name                 = "${var.name_prefix}-web"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = var.kms_key_arn != null ? "KMS" : "AES256"
    kms_key         = var.kms_key_arn
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-web"
  })
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.untagged_image_expiration_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_expiration_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep the ${var.image_retention_count} most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      },
    ]
  })
}

# Lambda pulls the image with the service principal rather than the execution
# role. Granting it explicitly keeps Lambda from appending its own statement
# to this policy (which Terraform would then report as drift).
data "aws_iam_policy_document" "ecr" {
  statement {
    sid    = "LambdaECRImageRetrievalPolicy"
    effect = "Allow"

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:sourceArn"
      values   = ["${local.function_arn_prefix}*"]
    }
  }
}

resource "aws_ecr_repository_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.ecr.json
}
