terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "qwik-infra-terraform-state"
    key          = "dev/terraform.tfstate"
    region       = "ap-northeast-2"
    profile      = "qwik"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "qwik"
}

module "network" {
  source = "../modules/terraform-aws-network"

  project_name = "qwik-dev"
}
