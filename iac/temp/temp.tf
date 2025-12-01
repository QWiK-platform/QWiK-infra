# 가용 영역 데이터 가져오기 (하드코딩 방지)
data "aws_availability_zones" "available" {
  state = "available"
}

# -------------------------
# VPC & Network
# -------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "QWiK-VPC" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "QWiK-IGW" }
}

# -------------------------
# Subnets
# -------------------------

# Public Subnet A (ALB, NAT GW 배치) - ap-northeast-2a
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = { Name = "QWiK-Public-Subnet-A" }
}

# Public Subnet C (ALB 고가용성용) - ap-northeast-2c
resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[2] # 보통 c존
  map_public_ip_on_launch = true

  tags = { Name = "QWiK-Public-Subnet-C" }
}

# Private Subnet A (EC2 배치) - ap-northeast-2a
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = { Name = "QWiK-Private-Subnet-A" }
}

# -------------------------
# NAT Gateway
# -------------------------

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "QWiK-NAT-EIP" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id # Public Subnet에 위치

  tags = { Name = "QWiK-NAT-GW" }

  depends_on = [aws_internet_gateway.main]
}

# -------------------------
# Routing
# -------------------------

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "QWiK-Public-RT" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = { Name = "QWiK-Private-RT" }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# -------------------------
# Security Groups
# -------------------------

# ALB SG: 어디서든 80포트 허용
resource "aws_security_group" "alb_sg" {
  name   = "qwik-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "QWiK-ALB-SG" }
}

# Web Server SG: ALB로부터 오는 트래픽만 허용
resource "aws_security_group" "web_sg" {
  name   = "qwik-web-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb_sg.id] # ALB SG ID 참조
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "QWiK-Web-SG" }
}

# -------------------------
# Load Balancer (ALB)
# -------------------------

resource "aws_lb" "main" {
  name               = "qwik-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_c.id]

  tags = { Name = "QWiK-ALB" }
}

resource "aws_lb_target_group" "web" {
  name     = "qwik-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path    = "/"
    matcher = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# -------------------------
# EC2 Instance
# -------------------------

resource "aws_instance" "web" {
  # Ubuntu 24.04 LTS (ap-northeast-2)
  ami = "ami-040c33c6a51fd5d96"

  instance_type = "t3.small"

  subnet_id = aws_subnet.private_a.id

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  tags = { Name = "QWiK-Private-Web" }
}

# EC2를 ALB Target Group에 등록
resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web.id
  port             = 80
}

# -------------------------
# IAM Role for SSM
# -------------------------

# 1) SSM 역할을 수행할 IAM Role 생성
resource "aws_iam_role" "ssm_role" {
  name = "qwik-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = { Name = "QWiK-SSM-Role" }
}

# 2) AmazonSSMManagedInstanceCore
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 3) EC2에 부착하기 위한 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "qwik-ec2-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# -------------------------
# Outputs
# -------------------------

output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "Access this DNS to test the web server"
}
