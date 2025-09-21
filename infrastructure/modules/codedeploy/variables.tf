variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "orders_service_name" {
  description = "Name of the orders ECS service"
  type        = string
}

variable "inventory_service_name" {
  description = "Name of the inventory ECS service"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener for traffic routing"
  type        = string
}

variable "orders_target_group_name" {
  description = "Name of the orders service blue target group"
  type        = string
}

variable "orders_target_group_name_green" {
  description = "Name of the orders service green target group"
  type        = string
}

variable "inventory_target_group_name" {
  description = "Name of the inventory service blue target group"
  type        = string
}

variable "inventory_target_group_name_green" {
  description = "Name of the inventory service green target group"
  type        = string
}

variable "orders_target_group_arn_suffix" {
  description = "ARN suffix of the orders service target group for CloudWatch alarms"
  type        = string
}

variable "inventory_target_group_arn_suffix" {
  description = "ARN suffix of the inventory service target group for CloudWatch alarms"
  type        = string
}

