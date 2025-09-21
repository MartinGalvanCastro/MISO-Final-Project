output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}


output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "log_groups" {
  description = "Map of service names to CloudWatch log group names"
  value = {
    orders_service    = aws_cloudwatch_log_group.orders_service.name
    inventory_service = aws_cloudwatch_log_group.inventory_service.name
    prometheus        = aws_cloudwatch_log_group.prometheus.name
    grafana          = aws_cloudwatch_log_group.grafana.name
  }
}

output "services" {
  description = "Map of ECS service ARNs"
  value = {
    orders_service    = aws_ecs_service.orders_service.id
    inventory_service = aws_ecs_service.inventory_service.id
    prometheus        = aws_ecs_service.prometheus.id
    grafana          = aws_ecs_service.grafana.id
  }
}

output "task_definitions" {
  description = "Map of ECS task definition ARNs"
  value = {
    orders_service    = aws_ecs_task_definition.orders_service.arn
    inventory_service = aws_ecs_task_definition.inventory_service.arn
    prometheus        = aws_ecs_task_definition.prometheus.arn
    grafana          = aws_ecs_task_definition.grafana.arn
  }
}

output "orders_service_name" {
  description = "Name of the orders ECS service"
  value       = aws_ecs_service.orders_service.name
}

output "inventory_service_name" {
  description = "Name of the inventory ECS service"
  value       = aws_ecs_service.inventory_service.name
}

output "prometheus_service_name" {
  description = "Name of the prometheus ECS service"
  value       = aws_ecs_service.prometheus.name
}

output "grafana_service_name" {
  description = "Name of the grafana ECS service"
  value       = aws_ecs_service.grafana.name
}