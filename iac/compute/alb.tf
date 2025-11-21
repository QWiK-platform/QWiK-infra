# iac/compute/alb.tf

# ALB 생성
resource "aws_lb" "qwik_alb" {
  name               = "QWiK-ALB-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.k8s_external.id]
  
  # Public Subnet 3개 모두 지정 (고가용성)
  subnets = [
    data.terraform_remote_state.base.outputs.public_subnet_az1_id,
    data.terraform_remote_state.base.outputs.public_subnet_az2_id,
    data.terraform_remote_state.base.outputs.public_subnet_az3_id
  ]

  tags = { 
    Name        = "QWiK-ALB-${var.environment}" 
    Environment = var.environment
  }
}

# Target Group
resource "aws_lb_target_group" "k8s_tg" {
  name     = "QWiK-TG-${var.environment}"
  port     = 30080 # K8s NodePort
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.base.outputs.vpc_id
  
  health_check {
    # path = "/healthz" # (나중에 애플리케이션에 맞게 수정 가능)
    path = "/"
    port = 30080
  }
}

# EC2 연결
resource "aws_lb_target_group_attachment" "master" {
  target_group_arn = aws_lb_target_group.k8s_tg.arn
  target_id        = aws_instance.k8s_master.id
  port             = 30080
}
resource "aws_lb_target_group_attachment" "worker" {
  target_group_arn = aws_lb_target_group.k8s_tg.arn
  target_id        = aws_instance.k8s_worker.id
  port             = 30080
}

# 리스너
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.qwik_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_tg.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.qwik_alb.dns_name
}
