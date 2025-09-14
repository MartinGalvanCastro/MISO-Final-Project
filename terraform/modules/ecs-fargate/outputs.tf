# ECS Cluster Outputs
output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = var.create_cluster ? aws_ecs_cluster.cluster[0].id : var.existing_cluster_id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = var.create_cluster ? aws_ecs_cluster.cluster[0].name : var.existing_cluster_name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = var.create_cluster ? aws_ecs_cluster.cluster[0].arn : null
}

# ECS Service Outputs
output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.service.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.service.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.service.id
}

# Task Definition Outputs
output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.task.arn
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.task.family
}

output "task_definition_revision" {
  description = "Revision of the task definition"
  value       = aws_ecs_task_definition.task.revision
}

# IAM Role Outputs
output "task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.task_execution_role.arn
}

output "task_role_arn" {
  description = "ARN of the task role"
  value       = aws_iam_role.task_role.arn
}

# Security Group Outputs
output "security_group_id" {
  description = "ID of the ECS service security group"
  value       = aws_security_group.ecs_service.id
}

# Auto Scaling Outputs
output "autoscaling_target_resource_id" {
  description = "Resource ID of the autoscaling target"
  value       = aws_appautoscaling_target.ecs_target.resource_id
}

output "cpu_scaling_policy_arn" {
  description = "ARN of the CPU scaling policy"
  value       = aws_appautoscaling_policy.cpu_scaling_policy.arn
}

output "memory_scaling_policy_arn" {
  description = "ARN of the memory scaling policy"
  value       = aws_appautoscaling_policy.memory_scaling_policy.arn
}

# CloudWatch Outputs
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.service_logs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.service_logs.arn
}

output "high_cpu_alarm_arn" {
  description = "ARN of the high CPU alarm"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : null
}

output "high_memory_alarm_arn" {
  description = "ARN of the high memory alarm"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.high_memory[0].arn : null
}

# Complete Service Information
output "service_info" {
  description = "Complete ECS service information"
  value = {
    # Service Details
    service_name = aws_ecs_service.service.name
    service_arn  = aws_ecs_service.service.id
    cluster_name = var.create_cluster ? aws_ecs_cluster.cluster[0].name : var.existing_cluster_name

    # Task Configuration
    task_definition_arn = aws_ecs_task_definition.task.arn
    task_family        = aws_ecs_task_definition.task.family
    container_image    = var.container_image
    container_port     = var.container_port
    cpu               = var.cpu
    memory            = var.memory

    # Auto Scaling Configuration
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
    desired_count = var.desired_count

    # Networking
    vpc_id            = var.vpc_id
    subnet_ids        = var.subnet_ids
    security_group_id = aws_security_group.ecs_service.id

    # Logging
    log_group_name = aws_cloudwatch_log_group.service_logs.name

    # IAM Roles
    task_execution_role_arn = aws_iam_role.task_execution_role.arn
    task_role_arn          = aws_iam_role.task_role.arn
  }
}

# ECS CLI Commands
output "ecs_commands" {
  description = "Useful ECS CLI commands for service management"
  value = {
    describe_service = "aws ecs describe-services --cluster ${var.create_cluster ? aws_ecs_cluster.cluster[0].name : var.existing_cluster_name} --services ${aws_ecs_service.service.name}"

    list_tasks = "aws ecs list-tasks --cluster ${var.create_cluster ? aws_ecs_cluster.cluster[0].name : var.existing_cluster_name} --service-name ${aws_ecs_service.service.name}"

    update_service = "aws ecs update-service --cluster ${var.create_cluster ? aws_ecs_cluster.cluster[0].name : var.existing_cluster_name} --service ${aws_ecs_service.service.name} --force-new-deployment"

    scale_service = "aws ecs update-service --cluster ${var.create_cluster ? aws_ecs_cluster.cluster[0].name : var.existing_cluster_name} --service ${aws_ecs_service.service.name} --desired-count <count>"

    get_logs = "aws logs tail ${aws_cloudwatch_log_group.service_logs.name} --follow"

    exec_into_task = var.enable_execute_command ? "aws ecs execute-command --cluster ${var.create_cluster ? aws_ecs_cluster.cluster[0].name : var.existing_cluster_name} --task <task-id> --container ${var.service_name} --interactive --command /bin/bash" : "ECS Exec not enabled for this service"
  }
}