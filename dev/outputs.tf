# =============================================================================
# Network Outputs
# =============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = module.network.private_subnet_ids
}

# =============================================================================
# ALB Outputs
# =============================================================================

output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = aws_lb.this.dns_name
}

output "api_url" {
  description = "API URL (HTTPS)"
  value       = "https://api.qw1k.cloud"
}

# =============================================================================
# RDS Outputs
# =============================================================================

output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.this.endpoint
}

output "rds_port" {
  description = "RDS Port"
  value       = aws_db_instance.this.port
}

# =============================================================================
# ECS Outputs
# =============================================================================

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.this.name
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "ecs_api_service_name" {
  description = "ECS API Service Name"
  value       = aws_ecs_service.api.name
}

output "ecs_worker_task_definition_arn" {
  description = "ECS Worker Task Definition ARN (for EventBridge Pipes)"
  value       = aws_ecs_task_definition.worker.arn
}

# =============================================================================
# Security Group Outputs
# =============================================================================

output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "ecs_container_security_group_id" {
  description = "ECS Container (API) Security Group ID"
  value       = aws_security_group.ecs-container.id
}

output "ecs_worker_security_group_id" {
  description = "ECS Worker Security Group ID"
  value       = aws_security_group.ecs-worker.id
}

output "rds_security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

# =============================================================================
# IAM Role Outputs
# =============================================================================

output "ecs_task_execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ECS Task Role ARN (API)"
  value       = aws_iam_role.ecs_task.arn
}

output "ecs_worker_task_role_arn" {
  description = "ECS Worker Task Role ARN"
  value       = aws_iam_role.ecs_worker_task.arn
}

# =============================================================================
# SQS Outputs
# =============================================================================

output "sqs_queue_url" {
  description = "SQS Job Queue URL"
  value       = data.aws_sqs_queue.job_queue.url
}

output "sqs_queue_arn" {
  description = "SQS Job Queue ARN"
  value       = data.aws_sqs_queue.job_queue.arn
}

# =============================================================================
# EventBridge Pipes 수동 구축 시 필요한 정보들 - 추후 삭제예정
# =============================================================================

output "eventbridge_pipes_config" {
  description = "EventBridge Pipes 수동 구축 시 필요한 설정값"
  value = {
    source_sqs_arn          = data.aws_sqs_queue.job_queue.arn
    target_ecs_cluster_arn  = aws_ecs_cluster.this.arn
    target_task_definition  = aws_ecs_task_definition.worker.arn
    subnets                 = module.network.private_subnet_ids
    security_groups         = [aws_security_group.ecs-worker.id]
    task_execution_role_arn = aws_iam_role.ecs_task_execution.arn
    task_role_arn           = aws_iam_role.ecs_worker_task.arn
  }
}
