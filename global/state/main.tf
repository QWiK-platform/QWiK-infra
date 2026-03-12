provider "aws" {
  region  = "ap-northeast-2"
  profile = "qwik"
}

locals {
  tags = {
    app = "qwik"
    managed = "terraform"
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "qwik-infra-terraform-state"

  lifecycle {
    prevent_destroy = true
  }

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}
