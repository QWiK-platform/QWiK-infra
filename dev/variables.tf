# -- aws
variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

# -- ecs
variable "ecs_subnets" {
  type = list(string)
}

# -- cloudfront
variable "cf_distribution_id" {
  type = string
}

variable "cf_deployment_arn" {
  type = string
}

# -- ecr
variable "ecr_repository_url" {
  type = string
}

variable "ecr_worker_repository_url" {
  type = string
}

variable "worker_image_tag" {
  type = string
}

variable "image_tag" {
  type = string
}

# -- s3
variable "deploy_bucket_name" {
  type = string
}

# -- db
variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

# -- secret
variable "secret_key" {
  type      = string
  sensitive = true
}

variable "github_client_id" {
  type = string
}

variable "github_client_secret" {
  type      = string
  sensitive = true
}

variable "github_redirect_uri" {
  type = string
}

# -- kvs
variable "kvs_arn" {
  type = string
}

# -- datadog
variable "datadog_api" {
  type      = string
  sensitive = true
}