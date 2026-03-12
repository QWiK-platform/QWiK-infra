locals {
  ssm_prefix = "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/qwik/dev"

  secret_names = [
    "DATABASE_URL",
    "SECRET_KEY",
    "GITHUB_CLIENT_ID",
    "GITHUB_CLIENT_SECRET",
    "GITHUB_REDIRECT_URI",
    "SQS_QUEUE_URL",
    "S3_BUCKET_NAME",
    "KVS_ARN"
  ]
}