output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.vpc.alb_security_group_id
}

output "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = module.vpc.ecs_tasks_security_group_id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = module.vpc.rds_security_group_id
}

# ECR Outputs
output "ecr_repositories" {
  description = "ECR repository URLs"
  value       = module.ecr.ecr_repositories
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = module.ecr.github_actions_role_arn
}

# RDS Outputs
output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
}

output "db_name" {
  description = "Database name"
  value       = module.rds.db_name
}

output "db_secret_arn" {
  description = "ARN of the secret containing database credentials"
  value       = module.rds.secret_arn
}

# SQS Outputs
output "orders_queue_url" {
  description = "URL of the orders SQS queue"
  value       = module.sqs.orders_queue_url
}

output "orders_queue_arn" {
  description = "ARN of the orders SQS queue"
  value       = module.sqs.orders_queue_arn
}

output "ecs_sqs_role_arn" {
  description = "ARN of the ECS task role for SQS access"
  value       = module.sqs.ecs_sqs_role_arn
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.ecs.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.ecs.ecs_task_role_arn
}

output "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  value       = module.ecs.service_discovery_namespace_id
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "alb_target_groups" {
  description = "Map of service names to target group ARNs"
  value       = module.alb.target_groups
}

# ECS Service Outputs
output "ecs_services" {
  description = "Map of ECS service ARNs"
  value       = module.ecs.services
}

output "task_definitions" {
  description = "Map of ECS task definition ARNs"
  value       = module.ecs.task_definitions
}