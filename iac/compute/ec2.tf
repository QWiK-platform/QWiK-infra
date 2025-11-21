# iac/compute/ec2.tf

# ---------------------------------------------------------
# [1] AMI Data Source
# ---------------------------------------------------------
# Packer로 빌드한 '나만의 K8s 베이스 이미지'를 찾습니다.
# 이름 패턴: "qwik-k8s-base-v1-*"

data "aws_ami" "qwik_k8s_ami" {
  most_recent = true
  owners      = ["self"] # 내 계정에서 찾음

  filter {
    name   = "name"
    values = ["qwik-k8s-base-v1-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ---------------------------------------------------------
# [2] Master Node Instance
# ---------------------------------------------------------
# Private Subnet에 위치하며, 부팅 시 K8s Master로 초기화하고
# Join Token을 SSM Parameter Store에 저장합니다.

resource "aws_instance" "k8s_master" {
  # Packer로 만든 이미지 ID 사용
  ami           = data.aws_ami.qwik_k8s_ami.id
  instance_type = "t3.medium"

  # Base 스택의 Private Subnet 1번(AZ1)에 배치
  subnet_id = data.terraform_remote_state.base.outputs.private_subnet_ids[0]

  # SSM 접속 및 Parameter Store 접근을 위한 IAM Role
  iam_instance_profile = aws_iam_instance_profile.k8s_ssm_profile.name

  # Private Subnet이므로 공인 IP 없음
  associate_public_ip_address = false

  # 보안 그룹 (내부 통신 + 외부 허용)
  vpc_security_group_ids = [
    aws_security_group.k8s_internal.id,
    aws_security_group.k8s_external.id
  ]

  # SSH 접속용 키 페어 (비상용)
  # key_name = "qwik-key"

  # [Master 자동화 스크립트]
  # Packer 이미지에 이미 설치된 도구들을 사용하여 초기화만 수행
  user_data = <<-EOF
    #!/bin/bash
    
    # 1. 호스트네임 설정 (가시성 확보)
    hostnamectl set-hostname master-node

    # 2. Kubeadm Master 초기화
    # --pod-network-cidr: Calico 네트워크 플러그인 기본 대역
    # --ignore-preflight-errors: t3.medium vCPU 경고 무시
    kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=NumCPU

    # 3. Kubectl 권한 설정 (root 계정용)
    mkdir -p /root/.kube
    cp -i /etc/kubernetes/admin.conf /root/.kube/config
    
    # 4. Calico 네트워크 플러그인 설치 (Pod 통신용)
    kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

    # 5. [핵심] Join Command 생성 및 SSM 저장
    # 워커 노드가 사용할 토큰을 생성합니다.
    JOIN_CMD=$(kubeadm token create --print-join-command)
    
    # AWS SSM Parameter Store에 토큰(명령어) 업로드 (SecureString)
    aws ssm put-parameter \
      --name "/qwik/${var.environment}/k8s/join_cmd" \
      --value "$JOIN_CMD" \
      --type "SecureString" \
      --overwrite \
      --region ${var.aws_region}
  EOF

  tags = {
    Name        = "QWiK-K8s-Master-${var.environment}"
    Role        = "master"
    Environment = var.environment
  }
}

# ---------------------------------------------------------
# [3] Worker Node Instance
# ---------------------------------------------------------
# Private Subnet에 위치하며, 부팅 시 SSM에서 토큰을 가져와
# Master Node에 자동으로 Join 합니다.

resource "aws_instance" "k8s_worker" {
  # Packer로 만든 이미지 ID 사용
  ami           = data.aws_ami.qwik_k8s_ami.id
  instance_type = "t3.medium"

  # Master와 같은 서브넷에 배치 (레이턴시 최소화)
  subnet_id = data.terraform_remote_state.base.outputs.private_subnet_ids[0]

  # SSM 권한 필수
  iam_instance_profile        = aws_iam_instance_profile.k8s_ssm_profile.name
  associate_public_ip_address = false

  vpc_security_group_ids = [
    aws_security_group.k8s_internal.id,
    aws_security_group.k8s_external.id
  ]

  # key_name = "qwik-key"

  # Master가 먼저 생성되어야 함 (토큰 생성 대기)
  depends_on = [aws_instance.k8s_master]

  # [Worker 자동화 스크립트]
  user_data = <<-EOF
    #!/bin/bash
    
    # 1. 호스트네임 설정
    hostnamectl set-hostname worker-node-1

    # 2. [핵심] SSM에서 Join Command 가져오기 (Polling)
    # Master가 초기화를 끝내고 토큰을 올릴 때까지 반복해서 확인합니다.
    JOIN_CMD=""
    while [ -z "$JOIN_CMD" ]; do
      sleep 10
      echo "Waiting for Join Command from SSM..."
      JOIN_CMD=$(aws ssm get-parameter \
        --name "/qwik/${var.environment}/k8s/join_cmd" \
        --with-decryption \
        --query "Parameter.Value" \
        --output text \
        --region ${var.aws_region})
    done
    
    # 3. 가져온 명령어로 클러스터 Join 실행
    echo "Join Command Found! Executing..."
    $JOIN_CMD
  EOF

  tags = {
    Name        = "QWiK-K8s-Worker-${var.environment}"
    Role        = "worker"
    Environment = var.environment
  }
}

# ---------------------------------------------------------
# [4] Outputs
# ---------------------------------------------------------
# SSM 접속을 위해 인스턴스 ID와 Private IP를 출력합니다.

output "master_instance_id" {
  description = "Instance ID of the Master Node (Use for SSM)"
  value       = aws_instance.k8s_master.id
}

output "master_private_ip" {
  description = "Private IP of the Master Node"
  value       = aws_instance.k8s_master.private_ip
}

output "worker_instance_id" {
  description = "Instance ID of the Worker Node"
  value       = aws_instance.k8s_worker.id
}

output "worker_private_ip" {
  description = "Private IP of the Worker Node"
  value       = aws_instance.k8s_worker.private_ip
}
