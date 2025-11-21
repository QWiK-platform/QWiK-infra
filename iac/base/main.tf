# iac/base/main.tf

# 1. Terraform 버전 및 필수 프로바이더 설정
terraform {
  required_version = ">= 1.5.0" # Terraform 최소 버전 지정

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # AWS 프로바이더 버전 고정 (안정성)
    }
  }

  # 2. S3 백엔드 설정
  backend "s3" {
    bucket         = "qwik-terraform-state"
    key            = "base/terraform.tfstate"           # S3 버킷 내에 상태 파일이 저장될 경로
    region         = "ap-northeast-2"                     # S3 버킷이 있는 리전 (서울)
    dynamodb_table = "qwik-terraform-lock"                # 2단계에서 만든 DynamoDB 테이블 이름
    encrypt        = true                                 # 상태 파일 암호화
  }
}

# 3. AWS 프로바이더 기본 설정
provider "aws" {
  region = var.aws_region # 사용할 기본 리전 (variables.tf에서 정의)
}
