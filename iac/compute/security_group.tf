# iac/compute/security_group.tf

# K8s 내부 통신용 (Master <-> Worker)
resource "aws_security_group" "k8s_internal" {
  name        = "QWiK-K8s-Internal-${var.environment}"
  description = "Allow internal communication"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id

  # 자기 자신끼리는 모든 통신 허용
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  
  # 밖으로 나가는 건 모두 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = { 
    Name        = "QWiK-K8s-Internal-${var.environment}" 
    Environment = var.environment
  }
}

# 외부 트래픽 허용 (ALB 용)
resource "aws_security_group" "k8s_external" {
  name        = "QWiK-K8s-External-${var.environment}"
  description = "Allow traffic from ALB"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id

  # ALB가 NodePort로 쏘는 트래픽 허용 (30000~32767)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  
  # HTTP/HTTPS (Ingress용 예비 포트)
  ingress {
    from_port   = 80
    to_port     = 80
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
    Name        = "QWiK-K8s-External-${var.environment}"
    Environment = var.environment
  }
}
