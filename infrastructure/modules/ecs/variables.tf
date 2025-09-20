variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the ECS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS services"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for ECS tasks"
  type        = list(string)
}

variable "db_secret_arn" {
  description = "ARN of the database secret in Secrets Manager"
  type        = string
}

variable "sqs_access_policy_arn" {
  description = "ARN of the SQS access policy"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7  # Minimum for cost optimization
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "ecr_repositories" {
  description = "Map of ECR repository URLs"
  type = object({
    orders_service    = string
    inventory_service = string
    prometheus        = string
    grafana          = string
  })
}


variable "service_discovery_namespace_name" {
  description = "Name of the service discovery namespace"
  type        = string
  default     = "medisupply.local"
}

variable "orders_service_min_capacity" {
  description = "Minimum capacity for orders service auto scaling"
  type        = number
  default     = 2
}

variable "orders_service_max_capacity" {
  description = "Maximum capacity for orders service auto scaling"
  type        = number
  default     = 5
}

variable "inventory_service_desired_count" {
  description = "Desired count for inventory service"
  type        = number
  default     = 5
}

variable "orders_target_group_arn" {
  description = "ARN of the orders service target group"
  type        = string
}

variable "inventory_target_group_arn" {
  description = "ARN of the inventory service target group"
  type        = string
}

variable "prometheus_target_group_arn" {
  description = "ARN of the prometheus target group"
  type        = string
}

variable "grafana_target_group_arn" {
  description = "ARN of the grafana target group"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
}