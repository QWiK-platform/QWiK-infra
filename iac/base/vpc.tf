# iac/base/vpc.tf

# -------------------------
# VPC (10.0.0.0/16)
# -------------------------

resource "aws_vpc" "qwik_vpc" {
  # CIDR Block 설정
  cidr_block = "10.0.0.0/16"

  # DNS 설정
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "QWiK-VPC-${var.environment}"
    Environment = var.environment
  }
}

# -------------------------
# Subnets
# -------------------------

# -------------------------
# AZ 1 (ap-northeast-2a)
# -------------------------

# Public Subnet (10.0.1.0/24)
resource "aws_subnet" "qwik_public_subnet_az1" {
  # VPC에 연결
  vpc_id = aws_vpc.qwik_vpc.id

  # CIDR Block 설정
  cidr_block = "10.0.1.0/24"

  # AZ 설정
  availability_zone = "ap-northeast-2a"

  # Public IP
  map_public_ip_on_launch = true

  tags = {
    Name        = "QWiK-Public-Subnet-AZ1-${var.environment}"
    Environment = var.environment
  }
}

# Private Subnet (10.0.11.0/24)
resource "aws_subnet" "qwik_private_subnet_az1" {
  # VPC에 연결
  vpc_id = aws_vpc.qwik_vpc.id

  # CIDR Block 설정
  cidr_block = "10.0.11.0/24"

  # AZ 설정
  availability_zone = "ap-northeast-2a"

  tags = {
    Name        = "QWiK-Private-Subnet-AZ1-${var.environment}"
    Environment = var.environment
  }
}

# -------------------------
# AZ 2 (ap-northeast-2b)
# -------------------------

# Public Subnet (10.0.2.0/24)
resource "aws_subnet" "qwik_public_subnet_az2" {
  # VPC에 연결
  vpc_id = aws_vpc.qwik_vpc.id

  # CIDR Block 설정
  cidr_block = "10.0.2.0/24"

  # AZ 설정
  availability_zone = "ap-northeast-2b"

  # Public IP
  map_public_ip_on_launch = true

  tags = {
    Name        = "QWiK-Public-Subnet-AZ2-${var.environment}"
    Environment = var.environment
  }
}

# Private Subnet (10.0.12.0/24)
resource "aws_subnet" "qwik_private_subnet_az2" {
  # VPC에 연결
  vpc_id = aws_vpc.qwik_vpc.id

  # CIDR Block 설정
  cidr_block = "10.0.12.0/24"

  # AZ 설정
  availability_zone = "ap-northeast-2b"

  tags = {
    Name        = "QWiK-Private-Subnet-AZ2-${var.environment}"
    Environment = var.environment
  }
}

# -------------------------
# AZ 3 (ap-northeast-2c)
# -------------------------

# Public Subnet (10.0.3.0/24)
resource "aws_subnet" "qwik_public_subnet_az3" {
  # VPC에 연결
  vpc_id = aws_vpc.qwik_vpc.id

  # CIDR Block 설정
  cidr_block = "10.0.3.0/24"

  # AZ 설정
  availability_zone = "ap-northeast-2c"

  # Public IP
  map_public_ip_on_launch = true

  tags = {
    Name        = "QWiK-Public-Subnet-AZ3-${var.environment}"
    Environment = var.environment
  }
}

# Private Subnet (10.0.13.0/24)
resource "aws_subnet" "qwik_private_subnet_az3" {
  # VPC에 연결
  vpc_id = aws_vpc.qwik_vpc.id

  # CIDR Block 설정
  cidr_block = "10.0.13.0/24"

  # AZ 설정
  availability_zone = "ap-northeast-2c"

  tags = {
    Name        = "QWiK-Private-Subnet-AZ3-${var.environment}"
    Environment = var.environment
  }
}

# -------------------------
# Internet Gateway (IGW)
# -------------------------

resource "aws_internet_gateway" "qwik_igw" {
  # VPC에 연결
  vpc_id = aws_vpc.qwik_vpc.id

  tags = {
    Name        = "QWiK-IGW-${var.environment}"
    Environment = var.environment
  }
}

# -------------------------
# Route Table
# Public Subnet -> IGW
# -------------------------

resource "aws_route_table" "qwik_public_rt" {
  vpc_id = aws_vpc.qwik_vpc.id

  route {
    cidr_block = "0.0.0.0/0"                      # 모든 범위
    gateway_id = aws_internet_gateway.qwik_igw.id # IGW로 라우팅
  }

  tags = {
    Name        = "QWiK-Public-RouteTable-${var.environment}"
    Environment = var.environment
  }
}

# -------------------------
# Route Table Association
# Public Subnet에 Route Table 연결
# -------------------------

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.qwik_public_subnet_az1.id
  route_table_id = aws_route_table.qwik_public_rt.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.qwik_public_subnet_az2.id
  route_table_id = aws_route_table.qwik_public_rt.id
}

resource "aws_route_table_association" "public_az3" {
  subnet_id      = aws_subnet.qwik_public_subnet_az3.id
  route_table_id = aws_route_table.qwik_public_rt.id
}

# -------------------------
# Route Table
# Private Subnet -> NAT Gateway
# -------------------------

resource "aws_route_table" "qwik_private_rt" {
  vpc_id = aws_vpc.qwik_vpc.id

  tags = {
    Name        = "QWiK-Private-RouteTable-${var.environment}"
    Environment = var.environment
  }
}

# -------------------------
# Route Table Association
# Private Subnet에 Route Table 연결
# -------------------------

resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.qwik_private_subnet_az1.id
  route_table_id = aws_route_table.qwik_private_rt.id
}

resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.qwik_private_subnet_az2.id
  route_table_id = aws_route_table.qwik_private_rt.id
}

resource "aws_route_table_association" "private_az3" {
  subnet_id      = aws_subnet.qwik_private_subnet_az3.id
  route_table_id = aws_route_table.qwik_private_rt.id
}

