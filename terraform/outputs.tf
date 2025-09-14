# Orders Service ECR Outputs
output "orders_service_ecr_repository_url" {
  description = "URL of the orders service ECR repository"
  value       = module.orders_service_ecr.repository_url
}

output "orders_service_ecr_repository_arn" {
  description = "ARN of the orders service ECR repository"
  value       = module.orders_service_ecr.repository_arn
}

output "orders_service_repository_name" {
  description = "Name of the orders service ECR repository"
  value       = module.orders_service_ecr.repository_name
}

# Inventory Service ECR Outputs
output "inventory_service_ecr_repository_url" {
  description = "URL of the inventory service ECR repository"
  value       = module.inventory_service_ecr.repository_url
}

output "inventory_service_ecr_repository_arn" {
  description = "ARN of the inventory service ECR repository"
  value       = module.inventory_service_ecr.repository_arn
}

output "inventory_service_repository_name" {
  description = "Name of the inventory service ECR repository"
  value       = module.inventory_service_ecr.repository_name
}

# General Outputs
output "aws_region" {
  description = "AWS region used for the resources"
  value       = var.aws_region
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# Comprehensive ECR Repositories Information
output "ecr_repositories" {
  description = "Map of all ECR repositories created"
  value = {
    orders_service    = module.orders_service_ecr.repository_info
    inventory_service = module.inventory_service_ecr.repository_info
  }
}

# ECR Registry Information for CI/CD
output "ecr_registry_info" {
  description = "ECR registry information for CI/CD pipelines"
  value = {
    region     = var.aws_region
    account_id = module.orders_service_ecr.repository_registry_id
    repositories = {
      orders_service = {
        name = module.orders_service_ecr.repository_name
        url  = module.orders_service_ecr.repository_url
      }
      inventory_service = {
        name = module.inventory_service_ecr.repository_name
        url  = module.inventory_service_ecr.repository_url
      }
    }
  }
}

# SQS Outputs
output "orders_service_sqs_queue_url" {
  description = "URL of the orders service SQS queue"
  value       = module.orders_service_sqs.queue_url
}

output "orders_service_sqs_queue_arn" {
  description = "ARN of the orders service SQS queue"
  value       = module.orders_service_sqs.queue_arn
}

output "orders_service_sqs_queue_name" {
  description = "Name of the orders service SQS queue"
  value       = module.orders_service_sqs.queue_name
}

output "orders_service_sqs_dlq_url" {
  description = "URL of the orders service SQS dead letter queue (null - DLQ disabled)"
  value       = module.orders_service_sqs.dead_letter_queue_url
}

output "orders_service_sqs_dlq_arn" {
  description = "ARN of the orders service SQS dead letter queue (null - DLQ disabled)"
  value       = module.orders_service_sqs.dead_letter_queue_arn
}

# Comprehensive SQS Information
output "sqs_queues" {
  description = "Map of all SQS queues created"
  value = {
    orders_service = module.orders_service_sqs.queue_info
  }
}

# Application Configuration for Services
output "service_configuration" {
  description = "Configuration information for microservices"
  value = {
    orders_service = {
      # ECR Configuration
      ecr_repository_url = module.orders_service_ecr.repository_url
      ecr_repository_arn = module.orders_service_ecr.repository_arn

      # SQS Configuration (Event Publishing)
      sqs_queue_url = module.orders_service_sqs.queue_url
      sqs_queue_arn = module.orders_service_sqs.queue_arn

      # Application Config
      queue_config = module.orders_service_sqs.queue_config
    }

    inventory_service = {
      # ECR Configuration
      ecr_repository_url = module.inventory_service_ecr.repository_url
      ecr_repository_arn = module.inventory_service_ecr.repository_arn
    }

    # Environment Information
    region      = var.aws_region
    environment = var.environment
    project     = var.project_name
  }
}

# CodeBuild Outputs
output "orders_service_codebuild_project_name" {
  description = "Name of the orders service CodeBuild project"
  value       = module.orders_service_codebuild.project_name
}

output "orders_service_codebuild_project_arn" {
  description = "ARN of the orders service CodeBuild project"
  value       = module.orders_service_codebuild.project_arn
}

output "inventory_service_codebuild_project_name" {
  description = "Name of the inventory service CodeBuild project"
  value       = module.inventory_service_codebuild.project_name
}

output "inventory_service_codebuild_project_arn" {
  description = "ARN of the inventory service CodeBuild project"
  value       = module.inventory_service_codebuild.project_arn
}

# Comprehensive CodeBuild Information
output "codebuild_projects" {
  description = "Map of all CodeBuild projects created"
  value = {
    orders_service    = module.orders_service_codebuild.project_info
    inventory_service = module.inventory_service_codebuild.project_info
  }
}

# CI/CD Commands
output "cicd_commands" {
  description = "Useful commands for CI/CD operations"
  value = {
    orders_service = {
      start_build              = module.orders_service_codebuild.build_commands.start_build
      start_build_with_version = module.orders_service_codebuild.build_commands.start_build_with_version
      list_builds             = module.orders_service_codebuild.build_commands.list_builds
    }
    inventory_service = {
      start_build              = module.inventory_service_codebuild.build_commands.start_build
      start_build_with_version = module.inventory_service_codebuild.build_commands.start_build_with_version
      list_builds             = module.inventory_service_codebuild.build_commands.list_builds
    }
  }
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = module.vpc.nat_gateway_public_ips
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.arn
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = module.alb.security_group_id
}

output "target_group_arns" {
  description = "ARNs of the target groups"
  value       = module.alb.target_group_arns
}

# ECS Service Outputs - Orders Service
output "orders_service_name" {
  description = "Name of the orders ECS service"
  value       = module.orders_service_ecs.service_name
}

output "orders_service_arn" {
  description = "ARN of the orders ECS service"
  value       = module.orders_service_ecs.service_arn
}

output "orders_service_cluster_name" {
  description = "Name of the ECS cluster for orders service"
  value       = module.orders_service_ecs.cluster_name
}

output "orders_service_log_group_name" {
  description = "CloudWatch log group name for orders service"
  value       = module.orders_service_ecs.log_group_name
}

# ECS Service Outputs - Inventory Service
output "inventory_service_name" {
  description = "Name of the inventory ECS service"
  value       = module.inventory_service_ecs.service_name
}

output "inventory_service_arn" {
  description = "ARN of the inventory ECS service"
  value       = module.inventory_service_ecs.service_arn
}

output "inventory_service_log_group_name" {
  description = "CloudWatch log group name for inventory service"
  value       = module.inventory_service_ecs.log_group_name
}

# Complete ECS Services Information
output "ecs_services" {
  description = "Complete information about all ECS services"
  value = {
    orders_service = module.orders_service_ecs.service_info
    inventory_service = module.inventory_service_ecs.service_info

    cluster_info = {
      cluster_name = module.orders_service_ecs.cluster_name
      cluster_arn  = module.orders_service_ecs.cluster_arn
    }
  }
}

# Service URLs
output "service_urls" {
  description = "URLs to access the deployed services"
  value = {
    orders_service = {
      url = "http://${module.alb.dns_name}/api/orders"
      health_check = "http://${module.alb.dns_name}/api/orders/health"
      docs = "http://${module.alb.dns_name}/api/orders/docs"
    }
    inventory_service = {
      url = "http://${module.alb.dns_name}/api/inventory"
      health_check = "http://${module.alb.dns_name}/api/inventory/health"
      docs = "http://${module.alb.dns_name}/api/inventory/docs"
    }
    load_balancer = {
      dns_name = module.alb.dns_name
      zone_id  = module.alb.zone_id
    }
  }
}

# ECS Management Commands
output "ecs_management_commands" {
  description = "Useful ECS CLI commands for service management"
  value = {
    orders_service = module.orders_service_ecs.ecs_commands
    inventory_service = module.inventory_service_ecs.ecs_commands
  }
}

# CodeDeploy Outputs - Orders Service
output "orders_service_codedeploy_application_name" {
  description = "Name of the orders service CodeDeploy application"
  value       = var.enable_blue_green_deployment ? module.orders_service_codedeploy[0].application_name : null
}

output "orders_service_codedeploy_deployment_group_name" {
  description = "Name of the orders service CodeDeploy deployment group"
  value       = var.enable_blue_green_deployment ? module.orders_service_codedeploy[0].deployment_group_name : null
}

output "orders_service_codedeploy_config_name" {
  description = "Name of the orders service CodeDeploy configuration"
  value       = var.enable_blue_green_deployment ? module.orders_service_codedeploy[0].deployment_config_name : null
}

# CodeDeploy Outputs - Inventory Service
output "inventory_service_codedeploy_application_name" {
  description = "Name of the inventory service CodeDeploy application"
  value       = var.enable_blue_green_deployment ? module.inventory_service_codedeploy[0].application_name : null
}

output "inventory_service_codedeploy_deployment_group_name" {
  description = "Name of the inventory service CodeDeploy deployment group"
  value       = var.enable_blue_green_deployment ? module.inventory_service_codedeploy[0].deployment_group_name : null
}

output "inventory_service_codedeploy_config_name" {
  description = "Name of the inventory service CodeDeploy configuration"
  value       = var.enable_blue_green_deployment ? module.inventory_service_codedeploy[0].deployment_config_name : null
}

# Complete CodeDeploy Information
output "codedeploy_applications" {
  description = "Complete information about all CodeDeploy applications"
  value = var.enable_blue_green_deployment ? {
    orders_service = {
      application_name        = module.orders_service_codedeploy[0].application_name
      deployment_group_name   = module.orders_service_codedeploy[0].deployment_group_name
      deployment_config_name  = module.orders_service_codedeploy[0].deployment_config_name
      codedeploy_role_arn    = module.orders_service_codedeploy[0].codedeploy_role_arn
      ecr_push_rule_name     = module.orders_service_codedeploy[0].ecr_push_rule_name
      log_group_name         = module.orders_service_codedeploy[0].log_group_name
    }
    inventory_service = {
      application_name        = module.inventory_service_codedeploy[0].application_name
      deployment_group_name   = module.inventory_service_codedeploy[0].deployment_group_name
      deployment_config_name  = module.inventory_service_codedeploy[0].deployment_config_name
      codedeploy_role_arn    = module.inventory_service_codedeploy[0].codedeploy_role_arn
      ecr_push_rule_name     = module.inventory_service_codedeploy[0].ecr_push_rule_name
      log_group_name         = module.inventory_service_codedeploy[0].log_group_name
    }
  } : {}
}

# Deployment Commands
output "deployment_commands" {
  description = "Useful CodeDeploy CLI commands for manual deployments"
  value = var.enable_blue_green_deployment ? {
    orders_service = {
      create_deployment = "aws deploy create-deployment --application-name ${module.orders_service_codedeploy[0].application_name} --deployment-group-name ${module.orders_service_codedeploy[0].deployment_group_name} --deployment-config-name ${module.orders_service_codedeploy[0].deployment_config_name}"
      list_deployments = "aws deploy list-deployments --application-name ${module.orders_service_codedeploy[0].application_name}"
      stop_deployment = "aws deploy stop-deployment --deployment-id <DEPLOYMENT_ID> --auto-rollback-enabled"
    }
    inventory_service = {
      create_deployment = "aws deploy create-deployment --application-name ${module.inventory_service_codedeploy[0].application_name} --deployment-group-name ${module.inventory_service_codedeploy[0].deployment_group_name} --deployment-config-name ${module.inventory_service_codedeploy[0].deployment_config_name}"
      list_deployments = "aws deploy list-deployments --application-name ${module.inventory_service_codedeploy[0].application_name}"
      stop_deployment = "aws deploy stop-deployment --deployment-id <DEPLOYMENT_ID> --auto-rollback-enabled"
    }
  } : {}
}

# SRE Monitoring Outputs
output "monitoring_urls" {
  description = "URLs for SRE monitoring dashboards"
  value = var.enable_sre_monitoring ? {
    grafana_dashboard = module.monitoring[0].grafana_url
    prometheus_metrics = module.monitoring[0].prometheus_url
    load_test_dashboard = "${module.monitoring[0].grafana_url}/d/load-test-metrics"
  } : {}
}

output "monitoring_info" {
  description = "Complete monitoring stack information"
  sensitive   = true
  value = var.enable_sre_monitoring ? module.monitoring[0].monitoring_info : {}
}

output "cost_optimization_summary" {
  description = "Summary of cost optimization measures implemented"
  value = {
    cloudwatch_log_retention = {
      ecs_services = "${var.ecs_log_retention_days} days (reduced from 14)"
      codebuild = "${var.codebuild_log_retention_days} days (reduced from 14)"
      codedeploy = "${var.codedeploy_log_retention_days} days (reduced from 30)"
      monitoring = "${var.monitoring_log_retention_days} days"
    }
    prometheus_local_storage = "${var.prometheus_retention_days} days (bypasses CloudWatch)"
    estimated_savings = "60-80% reduction in CloudWatch logging costs"
    monitoring_approach = "Hybrid: CloudWatch for critical alerts, Prometheus+Grafana for detailed metrics"
  }
}

# Load Testing Information
output "load_testing_setup" {
  description = "Information for setting up load tests with monitoring"
  value = var.enable_sre_monitoring ? {
    monitoring_urls = {
      real_time_dashboard = "${module.monitoring[0].grafana_url}/d/load-test-metrics"
      prometheus_query = "${module.monitoring[0].prometheus_url}/graph"
    }
    key_metrics_to_monitor = [
      "Request rate (RPS)",
      "Response latency percentiles (50th, 95th, 99th)",
      "Active ECS task count",
      "CPU and memory usage per service",
      "Error rate percentage",
      "ALB target health"
    ]
    health_check_commands = module.monitoring[0].health_check_commands
  } : {
    monitoring_urls = null
    key_metrics_to_monitor = []
    health_check_commands = null
  }
}