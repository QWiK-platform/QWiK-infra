data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# -- ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name               = "qwik-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json

  tags = {
    Name = "qwik-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_ssm" {
  name = "qwik-ecs-ssm-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
          "ssm:GetParameters",
        ]
        Resource = "arn:aws:ssm:ap-northeast-2:*:parameter/qwik/*"
      }
    ]
  })
}

# -- ECS Task Role
resource "aws_iam_role" "ecs_task" {
  name               = "qwik-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json

  tags = {
    Name = "qwik-ecs-task-role"
  }
}

resource "aws_iam_role_policy" "api_sqs" {
  name = "qwik-api-sqs-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "sqs:SendMessage"
          ]
          Resource = data.aws_sqs_queue.job_queue.arn
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "api_kvs_s3" {
  name = "qwik-api-kvs-s3-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "cloudfront-keyvaluestore:DescribeKeyValueStore",
            "cloudfront-keyvaluestore:GetKey",
            "cloudfront-keyvaluestore:DeleteKey",
            "cloudfront-keyvaluestore:UpdateKey",
            "cloudfront-keyvaluestore:ListKeys",
            "cloudfront-keyvaluestore:PutKey"
          ]
          Resource = var.kvs_arn
        },
        {
          Effect = "Allow",
          Action = [
            "s3:ListBucket"
          ]
          Resource = "arn:aws:s3:::${var.deploy_bucket_name}"
        },
        {
          Effect = "Allow",
          Action = [
            "s3:DeleteObject"
          ]
          Resource = "arn:aws:s3:::${var.deploy_bucket_name}/*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "api_exec" {
  name = "qwik-api-exec-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
          ]
          Resource = "*"
        }
      ]
    }
  )
}


# -- ECS Worker Task Role
resource "aws_iam_role" "ecs_worker_task" {
  name               = "qwik-ecs-worker-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json

  tags = {
    Name = "qwik-ecs-worker-task-role"
  }
}

resource "aws_iam_role_policy" "worker_s3" {
  name = "qwik-worker-s3-policy"
  role = aws_iam_role.ecs_worker_task.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
        ]
        Resource = [
          "arn:aws:s3:::${var.deploy_bucket_name}",
          "arn:aws:s3:::${var.deploy_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "worker_kvs" {
  name = "qwik-worker-kvs-policy"
  role = aws_iam_role.ecs_worker_task.id

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "cloudfront-keyvaluestore:DescribeKeyValueStore",
            "cloudfront-keyvaluestore:PutKey"
          ]
          Resource = var.kvs_arn
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "worker_cloudfront" {
  name = "qwik-worker-cloudfront-policy"
  role = aws_iam_role.ecs_worker_task.id

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "cloudfront:CreateInvalidation"
          ]
          Resource : var.cf_deployment_arn
        }
      ]
    }
  )
}