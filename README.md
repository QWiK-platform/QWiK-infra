# QWiK Infrastructure

QWiK 프로젝트의 AWS 인프라를 Terraform으로 관리하는 IaC(Infrastructure as Code) 저장소입니다.

## 기술 스택

### AWS Services
| 서비스 | 용도 |
|--------|------|
| **ECS Fargate** | API 서비스 및 Worker Task 실행 |
| **RDS PostgreSQL 15** | 메인 데이터베이스 |
| **Application Load Balancer** | HTTPS 트래픽 라우팅 및 로드밸런싱 |
| **CloudFront + KeyValueStore** | CDN 및 동적 경로 매핑 |
| **EventBridge Pipes** | SQS → ECS 이벤트 기반 Task 트리거 |
| **SSM Parameter Store** | 시크릿 및 설정 관리 |
| **CloudWatch + Datadog** | 로그 수집, 메트릭, APM |

### IaC
- **Terraform** (~> 5.0)
- **AWS Provider** (ap-northeast-2)

---

## 아키텍처

### VPC Network 구조

<img width="400" height="600" alt="VPC Network" src="https://github.com/user-attachments/assets/95ccbcba-4d86-45bb-8c9a-0386bb181a73" />

- **Multi-AZ 구성**: 2개의 가용 영역으로 고가용성 확보
- **서브넷 분리**: Public(ALB), Private(ECS/RDS) 서브넷으로 보안 계층 구분
- **NAT Gateway**: Private 서브넷에서 외부 통신 지원

### ECS 서비스 구조

<img width="400" height="600" alt="ECS Service" src="https://github.com/user-attachments/assets/9f4f02a9-a34d-4566-8742-064b9d9afe81" />

- **API Service**: Fargate에서 상시 운영, Auto Scaling 지원
- **Sidecar 컨테이너**: Fluent Bit(로그), Datadog Agent(APM) 통합
- **Worker Task**: Fargate Spot으로 비용 최적화

### 배포 파이프라인

<img width="400" height="600" alt="Deployment Pipeline" src="https://github.com/user-attachments/assets/049e8940-e7c6-4275-9db6-3c1abed9b861" />

- **이벤트 기반 처리**: SQS → EventBridge Pipes → ECS RunTask
- **서버리스 트리거**: Lambda 없이 직접 ECS Task 실행

---

## 주요 설계 결정

| 결정 사항 | 선택 | 이유 |
|-----------|------|------|
| **컴퓨팅 플랫폼** | ECS Fargate | 서버 관리 불필요, 인프라 운영 오버헤드 최소화 |
| **Worker 용량 공급자** | FARGATE_SPOT | 비용 최적화 (On-Demand 대비 최대 70% 절감) |
| **이벤트 처리** | EventBridge Pipes | Lambda 중간 계층 없이 SQS → ECS 직접 연결로 단순화 |
| **로깅 파이프라인** | Fluent Bit + Datadog | 구조화된 로그 수집, APM 통합으로 관찰가능성 확보 |
| **시크릿 관리** | SSM Parameter Store | Secrets Manager 대비 비용 효율적 (자동 로테이션 불필요한 경우) |
| **배포 전략** | Rolling + Circuit Breaker | 무중단 배포, 실패 시 자동 롤백으로 안정성 확보 |
| **CDN 경로 매핑** | CloudFront Functions + KVS | 정적 설정 대신 동적 경로 매핑으로 유연성 확보 |

---

## 디렉토리 구조

```
├── dev/                          # Dev 환경 Terraform 설정
│   ├── main.tf                   # Provider, Backend, Network 모듈
│   ├── ecs.tf                    # ECS Cluster, Service, Task Definition
│   ├── alb.tf                    # ALB, Target Group, Listener
│   ├── rds.tf                    # PostgreSQL 인스턴스
│   ├── iam.tf                    # IAM Role (Execution, Task, Pipes)
│   ├── security_group.tf         # Security Group
│   ├── eventbridge.tf            # EventBridge Pipes
│   ├── ssm.tf                    # SSM Parameters
│   └── variables.tf              # 변수 정의
│
├── modules/
│   └── terraform-aws-network/    # VPC 네트워크 재사용 모듈
│
└── global/state/                 # S3 Backend 부트스트랩
```

---

## 사용 방법

```bash
# Terraform 초기화
cd dev && terraform init

# 변경 사항 확인
terraform plan

# 인프라 적용
terraform apply

# 설정 검증
terraform validate
```

---

## Terraform 관리 외 리소스

다음 리소스는 AWS 콘솔에서 별도 관리:
- S3 버킷
- Route53 호스팅 영역
- ACM 인증서
- CloudFront Distribution/Functions/KeyValueStore
- SQS 큐
- ECR 리포지토리

---

## 개선 예정

- [ ] 환경 분리 (dev/staging/prod)
- [ ] Terraform 모듈화 확대
- [ ] GitHub Actions CI/CD 파이프라인 연동
- [ ] Spot 인터럽션 시 Worker Task 재처리 로직
- [ ] CloudWatch 대시보드 자동화
