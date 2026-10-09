terraform {
  required_version = ">= 1.9, < 2.0.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # 5.46.0 added the `lambda` origin type for origin access control.
      version = ">= 5.46.0, < 7.0.0"
    }
  }
}
