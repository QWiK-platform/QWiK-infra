# iac/base/outputs.tf

output "qwik_frontend_url" {
  description = "The domain name of the QWiK Frontend CDN"
  # 생성된 CloudFront의 도메인 이름을 출력
  value = "https://${aws_cloudfront_distribution.qwik_frontend_cdn.domain_name}"
}

# -------------------------
# CI/CD
# -------------------------

# S3 버킷 이름
# CI/CD 파이프라인이 어느 버킷에 업로드할지 알 수 있도록 버킷 이름을 출력
output "qwik_frontend_bucket_id" {
  description = "The ID (name) of the QWiK Frontend S3 bucket"
  value       = aws_s3_bucket.qwik_frontend_bucket.id
}

# CloudFront ID
# CI/CD 파이프라인이 어느 CDN의 캐시를 삭제할지 알 수 있도록 CDN ID를 출력합니다.
output "qwik_frontend_cdn_id" {
  description = "The ID of the QWiK Frontend CloudFront distribution"
  value       = aws_cloudfront_distribution.qwik_frontend_cdn.id
}

# compute 스택이 참조할 VPC ID
output "vpc_id" {
  description = "The ID of the QWiK VPC"
  value       = aws_vpc.qwik_vpc.id
}

# compute 스택이 NAT GW를 배치할 Public Subnet 1의 ID
output "public_subnet_az1_id" {
  description = "The ID of the Public Subnet in AZ1"
  value       = aws_subnet.qwik_public_subnet_az1.id
}

# 나머지 public subnet의 id
output "public_subnet_az2_id" {
  description = "The ID of the Public Subnet in AZ2"
  value       = aws_subnet.qwik_public_subnet_az2.id
}

output "public_subnet_az3_id" {
  description = "The ID of the Public Subnet in AZ3"
  value       = aws_subnet.qwik_public_subnet_az3.id
}

# compute 스택이 경로를 추가할 Private Route Table의 ID
output "private_route_table_id" {
  description = "The ID of the Private Route Table"
  value       = aws_route_table.qwik_private_rt.id
}

# compute 스택(EKS)이 사용할 Private Subnet ID 목록
output "private_subnet_ids" {
  description = "List of Private Subnet IDs"
  value = [
    aws_subnet.qwik_private_subnet_az1.id,
    aws_subnet.qwik_private_subnet_az2.id,
    aws_subnet.qwik_private_subnet_az3.id,
  ]
}

# RDS 접속 주소 (Endpoint)
output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.qwik_db.endpoint
}

# RDS 데이터베이스 이름 (기본 DB)
output "rds_db_name" {
  description = "The name of the database"
  value       = aws_db_instance.qwik_db.db_name
}

# SQS
output "sqs_queue_url" {
  description = "The URL of the SQS Queue"
  value       = aws_sqs_queue.qwik_job_queue.url
}
