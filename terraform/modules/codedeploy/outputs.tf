# CodeDeploy Application
output "application_name" {
  description = "Name of the CodeDeploy application"
  value       = aws_codedeploy_app.app.name
}

output "application_id" {
  description = "ID of the CodeDeploy application"
  value       = aws_codedeploy_app.app.id
}

# CodeDeploy Deployment Group
output "deployment_group_name" {
  description = "Name of the CodeDeploy deployment group"
  value       = aws_codedeploy_deployment_group.deployment_group.deployment_group_name
}

output "deployment_group_id" {
  description = "ID of the CodeDeploy deployment group"
  value       = aws_codedeploy_deployment_group.deployment_group.id
}

# CodeDeploy Deployment Configuration
output "deployment_config_name" {
  description = "Name of the custom deployment configuration"
  value       = aws_codedeploy_deployment_config.linear_10_percent.deployment_config_name
}

output "deployment_config_id" {
  description = "ID of the custom deployment configuration"
  value       = aws_codedeploy_deployment_config.linear_10_percent.deployment_config_id
}

# IAM Role
output "codedeploy_role_arn" {
  description = "ARN of the CodeDeploy service role"
  value       = aws_iam_role.codedeploy_role.arn
}

output "codedeploy_role_name" {
  description = "Name of the CodeDeploy service role"
  value       = aws_iam_role.codedeploy_role.name
}

# EventBridge Rule (if enabled)
output "ecr_push_rule_name" {
  description = "Name of the EventBridge rule for ECR push events"
  value       = var.enable_auto_deployment ? aws_cloudwatch_event_rule.ecr_push_rule[0].name : null
}

output "ecr_push_rule_arn" {
  description = "ARN of the EventBridge rule for ECR push events"
  value       = var.enable_auto_deployment ? aws_cloudwatch_event_rule.ecr_push_rule[0].arn : null
}

# CloudWatch Log Group
output "log_group_name" {
  description = "Name of the CloudWatch log group for CodeDeploy"
  value       = aws_cloudwatch_log_group.codedeploy_logs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group for CodeDeploy"
  value       = aws_cloudwatch_log_group.codedeploy_logs.arn
}