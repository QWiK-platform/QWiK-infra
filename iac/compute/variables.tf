# iac/compute/variables.tf

variable "aws_region" {
  description = "QWiK 플랫폼을 배포할 메인 AWS 리전"
  type        = string
  default     = "ap-northeast-2" # Seoul Region 
}

variable "environment" {
  type = string
}
