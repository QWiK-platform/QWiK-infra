# iac/base/rds.tf

# AWS SSM Parameter Store에서 비밀번호 읽어오기
data "aws_ssm_parameter" "db_password" {
  # 읽어올 파라미터의 이름 (환경 변수 사용)
  name            = "/qwik/${var.environment}/db/password"
  with_decryption = true # 암호화된 값을 복호화해서 가져옴
}

# ---------------------------------------------------------
# DB Subnet Group
# ---------------------------------------------------------
# RDS가 위치할 Private Subnet 그룹을 지정
resource "aws_db_subnet_group" "qwik_db_subnet_group" {
  name = "qwik-db-subnet-group-${var.environment}"
  subnet_ids = [
    aws_subnet.qwik_private_subnet_az1.id,
    aws_subnet.qwik_private_subnet_az2.id,
    aws_subnet.qwik_private_subnet_az3.id
  ]

  tags = {
    Name = "QWiK-DB-Subnet-Group-${var.environment}"
  }
}

# ---------------------------------------------------------
# DB Security Group (Firewall)
# ---------------------------------------------------------
resource "aws_security_group" "qwik_db_sg" {
  name        = "QWiK-DB-SG-${var.environment}"
  description = "Allow access to RDS (PostgreSQL)"
  vpc_id      = aws_vpc.qwik_vpc.id

  # PostgreSQL 기본 포트인 5432를 개방
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.qwik_vpc.cidr_block] # VPC 내부에서만 접근 허용
  }

  tags = { Name = "QWiK-DB-SG-${var.environment}" }
}

# ---------------------------------------------------------
# RDS Instance (PostgreSQL)
# ---------------------------------------------------------
resource "aws_db_instance" "qwik_db" {
  identifier = "qwik-db-${var.environment}"

  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  port = 5432

  username = "qwikadmin"
  password = data.aws_ssm_parameter.db_password.value

  db_subnet_group_name   = aws_db_subnet_group.qwik_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.qwik_db_sg.id]

  # snapshot settings
  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name        = "QWiK-DB-${var.environment}"
    Environment = var.environment
  }
}
