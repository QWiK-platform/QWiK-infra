# -- RDS Parameters
resource "aws_ssm_parameter" "database_url" {
  name  = "/qwik/dev/DATABASE_URL"
  type  = "SecureString"
  value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.this.endpoint}/${aws_db_instance.this.db_name}"

  tags = {
    Name = "qwik-database-url"
  }
}

# -- API Parameters
resource "aws_ssm_parameter" "secret_key" {
  name  = "/qwik/dev/SECRET_KEY"
  type  = "SecureString"
  value = var.secret_key

  tags = {
    Name = "qwik-secret-key"
  }
}

resource "aws_ssm_parameter" "sqs_queue_url" {
  name  = "/qwik/dev/SQS_QUEUE_URL"
  type  = "SecureString"
  value = data.aws_sqs_queue.job_queue.url # 여기만 다르게 설정함

  tags = {
    Name = "qwik-sqs_queue_url"
  }
}

resource "aws_ssm_parameter" "s3_bucket_name" {
  name  = "/qwik/dev/S3_BUCKET_NAME"
  type  = "String"
  value = var.deploy_bucket_name

  tags = {
    Name = "qwik-s3_bucket_name"
  }
}

resource "aws_ssm_parameter" "kvs_arn" {
  name  = "/qwik/dev/KVS_ARN"
  type  = "String"
  value = var.kvs_arn

  tags = {
    Name = "qwik-kvs_arn"
  }
}

# -- Github OAuth Parameters
resource "aws_ssm_parameter" "github_client_id" {
  name  = "/qwik/dev/GITHUB_CLIENT_ID"
  type  = "String"
  value = var.github_client_id

  tags = {
    Name = "qwik-github-client-id"
  }
}

resource "aws_ssm_parameter" "github_client_secret" {
  name  = "/qwik/dev/GITHUB_CLIENT_SECRET"
  type  = "SecureString"
  value = var.github_client_secret

  tags = {
    Name = "qwik-github-client-secret"
  }
}

resource "aws_ssm_parameter" "github_redirect_uri" {
  name  = "/qwik/dev/GITHUB_REDIRECT_URI"
  type  = "String"
  value = var.github_redirect_uri

  tags = {
    Name = "qwik-github-redirect-uri"
  }
}

# -- Datadog
resource "aws_ssm_parameter" "datadog_api" {
  name  = "/qwik/dev/DATADOG_API"
  type  = "SecureString"
  value = var.datadog_api

  tags = {
    Name = "qwik-datadog_api"
  }
}