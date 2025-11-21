# iac/compute/nat.tf

# -------------------------
# [1] Elastic IP (EIP)
# -------------------------
# NAT Gateway를 위한 고정 IP

resource "aws_eip" "qwik_nat_eip" {
  domain = "vpc"

  tags = {
    Name        = "QWiK-NAT-EIP-${var.environment}"
    Environment = var.environment
  }
}

# -------------------------
# [2] NAT Gateway
# -------------------------
# base 스택이 만든 Public Subnet 1에 NAT GW를 배치

resource "aws_nat_gateway" "qwik_nat_gw" {
  allocation_id = aws_eip.qwik_nat_eip.id

  # base 스택의 public_subnet_az1_id 값을 읽어오기
  subnet_id = data.terraform_remote_state.base.outputs.public_subnet_az1_id

  tags = {
    Name        = "QWiK-NAT-GW-${var.environment}"
    Environment = var.environment
  }
}

# -------------------------
# Private Route Table에 경로 추가
# -------------------------
# base 스택이 만든 Private Route Table에 Route 경로를 추가

resource "aws_route" "private_internet_access" {
  # base 스택의 private_route_table_id 값을 읽어오기
  route_table_id = data.terraform_remote_state.base.outputs.private_route_table_id

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.qwik_nat_gw.id
}
