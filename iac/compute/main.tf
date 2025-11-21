# iac/compute/main.tf

# 1. Terraform 버전 및 프로바이더 설정
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 2. S3 백엔드 설정
  backend "s3" {
    bucket         = "qwik-terraform-state" # base와 동일한 버킷 이름
    key            = "compute/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "qwik-terraform-lock" # base와 동일한 락 테이블
    encrypt        = true
  }
}

# 3. AWS 프로바이더 기본 설정
provider "aws" {
  region = var.aws_region
}

# 4. base 스택의 Output 값 읽어오기
data "terraform_remote_state" "base" {
  backend = "s3"

  workspace = terraform.workspace

  config = {
    bucket = "qwik-terraform-state" # base와 동일한 버킷 이름
    key    = "base/terraform.tfstate" # base의 상태 파일 경로
    region = "ap-northeast-2"
  }
}
