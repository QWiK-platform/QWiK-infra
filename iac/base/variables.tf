# iac/base/variables.tf

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2" # 서울 리전
}

variable "environment" {
  type = string
}

variable "qwik_frontend_bucket_name" {
  description = "FE bucket name"
  type = string
  default = "qwik-frontend-bucket-2025"
}

