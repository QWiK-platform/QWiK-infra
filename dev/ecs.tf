# -- ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "qwik-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "qwik-cluster"
  }
}

# -- ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = 0
  }
}

# -- CloudWatch Log Group for API
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/qwik-api"
  retention_in_days = 7

  tags = {
    Name = "qwik-api-logs"
  }
}

# -- CloudWatch Log Group for Datadog Agent
resource "aws_cloudwatch_log_group" "datadog_agent" {
  name              = "/ecs/qwik-datadog-agent"
  retention_in_days = 7

  tags = {
    Name = "qwik-datadog-agent-logs"
  }
}

# -- ECS Task Definition for API
resource "aws_ecs_task_definition" "api" {
  family                   = "qwik-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    # fluent bit (firelens)
    {
      name      = "qwik-log-router"
      image     = "amazon/aws-for-fluent-bit:stable"
      essential = true

      firelensConfiguration = {
        type = "fluentbit"
        options = {
          "enable-ecs-log-metadata" = "true"
        }
      }

      memoryReservation = 50

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/qwik-api"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "firelens"
        }
      }
    },
    # datadog agent
    {
      name      = "qwik-datadog-agent"
      image     = "public.ecr.aws/datadog/agent:latest"
      essential = true

      memoryReservation = 256

      portMappings = [
        {
          containerPort = 8126
          hostPort      = 8126
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ECS_FARGATE"
          value = "true"
        },
        {
          name  = "DD_SITE"
          value = "ap1.datadoghq.com"
        },
        {
          name  = "DD_APM_ENABLE"
          value = "true"
        },
        {
          name  = "DD_APM_NON_LOCAL_TRAFFIC"
          value = "true"
        }
      ]

      secrets = [
        {
          name      = "DD_API_KEY"
          valueFrom = "/qwik/dev/DATADOG_API"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/qwik-datadog-agent"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "datadog"
        }
      }
    },
    {
      name  = "qwik-api"
      image = "${var.ecr_repository_url}:${var.image_tag}"

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      secrets = [
        for name in local.secret_names : {
          name      = name
          valueFrom = "${local.ssm_prefix}/${name}"
        }
      ]

      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          "Name"       = "datadog"
          "Host"       = "http-intake.logs.ap1.datadoghq.com"
          "dd_service" = "qwik-api"
          "dd_source"  = "ecs"
          "dd_tags"    = "env:dev,project:qwik"
          "TLS"        = "on"
          "provider"   = "ecs"
        }
        secretOptions = [
          {
            name      = "apikey"
            valueFrom = "/qwik/dev/DATADOG_API"
          }
        ]
      }

      essential = true

      depends_on = [
        {
          containerName = "qwik-log-router"
          condition     = "START"
        }
      ]
    }
  ])
  tags = {
    Name = "qwik-api-task-definition"
  }
}

# -- ECS Service for API
resource "aws_ecs_service" "api" {
  name                   = "qwik-api-service"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.api.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets = [
      for idx in var.ecs_subnets : module.network.private_subnet_ids[idx]
    ]
    security_groups  = [aws_security_group.ecs-container.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "qwik-api"
    container_port   = 8000
  }

  # github actions로 배포하므로 추후 변경사항이 생겨 terraform apply시 충돌방지
  lifecycle {
    ignore_changes = [
      task_definition,
    ]
  }

  depends_on = [aws_lb_listener.https]

  tags = {
    Name = "qwik-api-service"
  }
}

# -- CloudWatch Log Group for Worker
resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/qwik-worker"
  retention_in_days = 7

  tags = {
    Name = "qwik-worker-logs"
  }
}

# -- ECS Task Definition for Worker
resource "aws_ecs_task_definition" "worker" {
  family                   = "qwik-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_worker_task.arn

  container_definitions = jsonencode([
    {
      name  = "qwik-worker"
      image = "${var.ecr_worker_repository_url}:${var.worker_image_tag}"

      environment = [
        {
          name  = "SQS_QUEUE_URL"
          value = data.aws_sqs_queue.job_queue.url
        },
        {
          name  = "S3_BUCKET_NAME"
          value = var.deploy_bucket_name
        },
        {
          name  = "KVS_ARN"
          value = var.kvs_arn
        },
        {
          name  = "DISTRIBUTION_ID"
          value = var.cf_distribution_id
        },
        {
          name  = "PYTHONUNBUFFERED",
          value = "1"
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${local.ssm_prefix}/DATABASE_URL"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/qwik-worker"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = {
    Name = "qwik-worker-task-definition"
  }
}