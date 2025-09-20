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

variable "prometheus_service_name" {
  description = "Name of the prometheus ECS service"
  type        = string
}

variable "grafana_service_name" {
  description = "Name of the grafana ECS service"
  type        = string
}

variable "orders_target_group_name" {
  description = "Name of the orders target group"
  type        = string
}

variable "inventory_target_group_name" {
  description = "Name of the inventory target group"
  type        = string
}

variable "prometheus_target_group_name" {
  description = "Name of the prometheus target group"
  type        = string
}

variable "grafana_target_group_name" {
  description = "Name of the grafana target group"
  type        = string
}