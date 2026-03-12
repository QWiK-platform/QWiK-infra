# sqs.tf

data "aws_sqs_queue" "job_queue" {
  name = "qwik-job-queue-dev"
}