# -- EventBridge Pipes IAM Role
data "aws_iam_policy_document" "pipes_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["pipes.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pipes" {
  name               = "qwik-eventbridge-pipes-role"
  assume_role_policy = data.aws_iam_policy_document.pipes_assume_role.json

  tags = {
    Name = "qwik-eventbridge-pipes-role"
  }
}

resource "aws_iam_role_policy" "pipes_sqs_ecs" {
  name = "qwik-pipes-policy"
  role = aws_iam_role.pipes.id

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes"
          ],
          "Resource" : data.aws_sqs_queue.job_queue.arn
        },
        {
          "Effect" : "Allow",
          "Action" : "ecs:RunTask",
          "Resource" : "${aws_ecs_task_definition.worker.arn_without_revision}:*"
        },
        {
          "Effect" : "Allow",
          "Action" : "iam:PassRole",
          "Resource" : [
            aws_iam_role.ecs_task_execution.arn,
            aws_iam_role.ecs_worker_task.arn
          ]
        }
      ]
    }
  )
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/pipes_pipe
# -- CloudWatch Log Group for Pipes
resource "aws_cloudwatch_log_group" "pipes" {
  name              = "/pipes/qwik-build-pipe"
  retention_in_days = 7

  tags = {
    Name = "qwik-build-pipe-logs"
  }
}

# -- EventBridge Pipes
resource "aws_pipes_pipe" "sqs_to_ecs" {
  name     = "qwik-build-pipe"
  role_arn = aws_iam_role.pipes.arn
  source   = data.aws_sqs_queue.job_queue.arn
  target   = aws_ecs_cluster.this.arn

  log_configuration {
    level = "ERROR"
    cloudwatch_logs_log_destination {
      log_group_arn = aws_cloudwatch_log_group.pipes.arn
    }
  }

  source_parameters {
    sqs_queue_parameters {
      batch_size = 1
    }
  }

  # 작성해둔 노션 참고하기
  target_parameters {
    ecs_task_parameters {
      task_definition_arn = aws_ecs_task_definition.worker.arn
      task_count          = 1

      capacity_provider_strategy {
        capacity_provider = "FARGATE_SPOT"
        weight            = 1
        base              = 0
      }

      network_configuration {
        aws_vpc_configuration {
          subnets          = [for idx in var.ecs_subnets : module.network.private_subnet_ids[idx]]
          security_groups  = [aws_security_group.ecs-container.id]
          assign_public_ip = "DISABLED"
        }
      }

      overrides {
        container_override {
          name   = "qwik-worker"
          cpu    = 512
          memory = 1024

          environment {
            name  = "REPO_URL"
            value = "$.body.repo_url"
          }
          environment {
            name  = "USER_ID"
            value = "$.body.user_id"
          }
          environment {
            name  = "DEPLOYMENT_ID"
            value = "$.body.deployment_id"
          }
          environment {
            name  = "USERNAME"
            value = "$.body.username"
          }
          environment {
            name = "PROJECT_ID"
            value = "$.body.project_id"
          }
        }
      }
    }
  }
  tags = {
    Name = "qwik-build-pipe"
  }
}