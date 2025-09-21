output "codedeploy_app_name" {
  description = "Name of the CodeDeploy application"
  value       = aws_codedeploy_app.ecs_app.name
}

output "orders_deployment_group_name" {
  description = "Name of the orders deployment group"
  value       = aws_codedeploy_deployment_group.orders_service.deployment_group_name
}

output "inventory_deployment_group_name" {
  description = "Name of the inventory deployment group"
  value       = aws_codedeploy_deployment_group.inventory_service.deployment_group_name
}


output "codedeploy_service_role_arn" {
  description = "ARN of the CodeDeploy service role"
  value       = aws_iam_role.codedeploy_service_role.arn
}