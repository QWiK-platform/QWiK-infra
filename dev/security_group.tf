# -- ALB SG
resource "aws_security_group" "alb" {
  name   = "qwik-alb-sg"
  vpc_id = module.network.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "qwik-alb-sg"
  }
}

# -- ECS Container SG
resource "aws_security_group" "ecs-container" {
  name   = "qwik-api-server-sg"
  vpc_id = module.network.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "qwik-api-server-sg"
  }
}

# -- ECS Worker SG
resource "aws_security_group" "ecs-worker" {
  name   = "qwik-worker-sg"
  vpc_id = module.network.vpc_id

  # Worker는 인바운드 트래픽 불필요 (EventBridge에서 실행만 됨)

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "qwik-worker-sg"
  }
}

# -- RDS SG
resource "aws_security_group" "rds" {
  name   = "qwik-rds-sg"
  vpc_id = module.network.vpc_id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [
      aws_security_group.ecs-container.id,
      aws_security_group.ecs-worker.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "qwik-rds-sg"
  }
}