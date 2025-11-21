# iac/base/sqs.tf

# -------------------------
# SQS (Simple Queue Service)
# -------------------------

resource "aws_sqs_queue" "qwik_job_queue" {
  name = "qwik-job-queue-${var.environment}"

  # 가시성 타임아웃 설정 (워커가 작업할 시간을 고려하여 설정)
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400 # 메시지 보관 기간 (1일)

  tags = {
    Name        = "QWiK-Job-Queue-${var.environment}"
    Environment = var.environment
  }
}
