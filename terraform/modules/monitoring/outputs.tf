# Service URLs
output "grafana_url" {
  description = "URL to access Grafana dashboard"
  value       = "http://${var.alb_dns_name}/grafana"
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://${var.alb_dns_name}/prometheus"
}

# Service Information
output "prometheus_service_name" {
  description = "Name of the Prometheus ECS service"
  value       = aws_ecs_service.prometheus.name
}

output "grafana_service_name" {
  description = "Name of the Grafana ECS service"
  value       = aws_ecs_service.grafana.name
}

output "prometheus_service_arn" {
  description = "ARN of the Prometheus ECS service"
  value       = aws_ecs_service.prometheus.id
}

output "grafana_service_arn" {
  description = "ARN of the Grafana ECS service"
  value       = aws_ecs_service.grafana.id
}

# Target Group Information
output "prometheus_target_group_arn" {
  description = "ARN of the Prometheus target group"
  value       = aws_lb_target_group.prometheus.arn
}

output "grafana_target_group_arn" {
  description = "ARN of the Grafana target group"
  value       = aws_lb_target_group.grafana.arn
}

# Security Groups
output "monitoring_security_group_id" {
  description = "ID of the monitoring security group"
  value       = aws_security_group.monitoring.id
}

output "efs_security_group_id" {
  description = "ID of the EFS security group"
  value       = var.enable_persistent_storage ? aws_security_group.efs[0].id : null
}

# EFS Information
output "efs_file_system_id" {
  description = "ID of the EFS file system for persistent storage"
  value       = var.enable_persistent_storage ? aws_efs_file_system.monitoring_efs[0].id : null
}

output "efs_file_system_dns_name" {
  description = "DNS name of the EFS file system"
  value       = var.enable_persistent_storage ? aws_efs_file_system.monitoring_efs[0].dns_name : null
}

# CloudWatch Log Group
output "log_group_name" {
  description = "Name of the CloudWatch log group for monitoring services"
  value       = aws_cloudwatch_log_group.monitoring_logs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group for monitoring services"
  value       = aws_cloudwatch_log_group.monitoring_logs.arn
}

# IAM Role
output "monitoring_task_role_arn" {
  description = "ARN of the monitoring task IAM role"
  value       = aws_iam_role.monitoring_task_role.arn
}

# Complete monitoring information
output "monitoring_info" {
  description = "Complete information about the monitoring stack"
  value = {
    grafana = {
      service_name = aws_ecs_service.grafana.name
      service_arn  = aws_ecs_service.grafana.id
      url          = "http://${var.alb_dns_name}/grafana"
      target_group_arn = aws_lb_target_group.grafana.arn
      admin_password = var.grafana_admin_password
    }

    prometheus = {
      service_name = aws_ecs_service.prometheus.name
      service_arn  = aws_ecs_service.prometheus.id
      url          = "http://${var.alb_dns_name}/prometheus"
      target_group_arn = aws_lb_target_group.prometheus.arn
      retention_days = var.prometheus_retention_days
    }

    storage = var.enable_persistent_storage ? {
      efs_file_system_id = aws_efs_file_system.monitoring_efs[0].id
      efs_dns_name      = aws_efs_file_system.monitoring_efs[0].dns_name
    } : null

    security = {
      monitoring_sg_id = aws_security_group.monitoring.id
      efs_sg_id       = var.enable_persistent_storage ? aws_security_group.efs[0].id : null
    }

    logging = {
      log_group_name = aws_cloudwatch_log_group.monitoring_logs.name
      log_group_arn  = aws_cloudwatch_log_group.monitoring_logs.arn
      retention_days = var.log_retention_days
    }
  }
}

# Load Testing Dashboard URLs
output "load_test_dashboards" {
  description = "URLs for load testing specific dashboards"
  value = var.load_test_dashboard_enabled ? {
    system_overview  = "http://${var.alb_dns_name}/grafana/d/system-overview"
    load_test       = "http://${var.alb_dns_name}/grafana/d/load-test-metrics"
    service_performance = "http://${var.alb_dns_name}/grafana/d/service-performance"
    infrastructure  = "http://${var.alb_dns_name}/grafana/d/infrastructure-metrics"
  } : {}
}

# ECS Management Commands
output "ecs_management_commands" {
  description = "Useful ECS CLI commands for monitoring service management"
  value = {
    prometheus = {
      describe_service = "aws ecs describe-services --cluster ${var.ecs_cluster_name} --services ${aws_ecs_service.prometheus.name}"
      list_tasks      = "aws ecs list-tasks --cluster ${var.ecs_cluster_name} --service-name ${aws_ecs_service.prometheus.name}"
      update_service  = "aws ecs update-service --cluster ${var.ecs_cluster_name} --service ${aws_ecs_service.prometheus.name} --force-new-deployment"
      scale_service   = "aws ecs update-service --cluster ${var.ecs_cluster_name} --service ${aws_ecs_service.prometheus.name} --desired-count <COUNT>"
      get_logs       = "aws logs tail ${aws_cloudwatch_log_group.monitoring_logs.name} --follow --filter-pattern prometheus"
    }

    grafana = {
      describe_service = "aws ecs describe-services --cluster ${var.ecs_cluster_name} --services ${aws_ecs_service.grafana.name}"
      list_tasks      = "aws ecs list-tasks --cluster ${var.ecs_cluster_name} --service-name ${aws_ecs_service.grafana.name}"
      update_service  = "aws ecs update-service --cluster ${var.ecs_cluster_name} --service ${aws_ecs_service.grafana.name} --force-new-deployment"
      scale_service   = "aws ecs update-service --cluster ${var.ecs_cluster_name} --service ${aws_ecs_service.grafana.name} --desired-count <COUNT>"
      get_logs       = "aws logs tail ${aws_cloudwatch_log_group.monitoring_logs.name} --follow --filter-pattern grafana"
    }
  }
}

# Cost Optimization Information
output "cost_optimization_info" {
  description = "Information about cost optimization settings"
  value = var.enable_cost_optimization ? {
    cloudwatch_log_retention = "${var.log_retention_days} days (reduced for cost savings)"
    prometheus_retention    = "${var.prometheus_retention_days} days (local storage)"
    metrics_collection     = "Prometheus-based (reduced CloudWatch API calls)"
    storage_type          = var.enable_persistent_storage ? "EFS persistent storage" : "Ephemeral storage"
    estimated_monthly_savings = "~60-80% reduction in CloudWatch costs"
  } : {}
}

# Monitoring Stack Health Check Commands
output "health_check_commands" {
  description = "Commands to check the health of monitoring services"
  value = {
    prometheus_health = "curl -f http://${var.alb_dns_name}/prometheus/-/healthy"
    grafana_health   = "curl -f http://${var.alb_dns_name}/grafana/api/health"
    check_targets    = "curl -s http://${var.alb_dns_name}/prometheus/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'"
    check_metrics    = "curl -s http://${var.alb_dns_name}/prometheus/api/v1/label/__name__/values | jq '.data | length'"
  }
}