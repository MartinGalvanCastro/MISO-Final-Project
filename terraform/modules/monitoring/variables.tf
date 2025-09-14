# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID where monitoring services will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for monitoring services"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB HTTP listener"
  type        = string
}

# ECS Configuration
variable "ecs_cluster_id" {
  description = "ECS cluster ID where monitoring services will run"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

# Prometheus Configuration
variable "prometheus_image" {
  description = "Docker image for Prometheus"
  type        = string
  default     = "prom/prometheus:v2.47.0"
}

variable "prometheus_cpu" {
  description = "CPU units for Prometheus task"
  type        = number
  default     = 512

  validation {
    condition = contains([
      256, 512, 1024, 2048, 4096
    ], var.prometheus_cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "prometheus_memory" {
  description = "Memory (MB) for Prometheus task"
  type        = number
  default     = 1024

  validation {
    condition = contains([
      512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192
    ], var.prometheus_memory)
    error_message = "Memory must be a valid Fargate memory configuration."
  }
}

variable "prometheus_retention_days" {
  description = "Number of days to retain Prometheus metrics"
  type        = number
  default     = 15

  validation {
    condition     = var.prometheus_retention_days >= 1 && var.prometheus_retention_days <= 365
    error_message = "Prometheus retention must be between 1 and 365 days."
  }
}

variable "prometheus_listener_priority" {
  description = "Priority for Prometheus ALB listener rule"
  type        = number
  default     = 200

  validation {
    condition     = var.prometheus_listener_priority >= 1 && var.prometheus_listener_priority <= 50000
    error_message = "Listener priority must be between 1 and 50000."
  }
}

# Grafana Configuration
variable "grafana_image" {
  description = "Docker image for Grafana"
  type        = string
  default     = "grafana/grafana:10.1.0"
}

variable "grafana_cpu" {
  description = "CPU units for Grafana task"
  type        = number
  default     = 256

  validation {
    condition = contains([
      256, 512, 1024, 2048, 4096
    ], var.grafana_cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "grafana_memory" {
  description = "Memory (MB) for Grafana task"
  type        = number
  default     = 512

  validation {
    condition = contains([
      512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192
    ], var.grafana_memory)
    error_message = "Memory must be a valid Fargate memory configuration."
  }
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "grafana_listener_priority" {
  description = "Priority for Grafana ALB listener rule"
  type        = number
  default     = 201

  validation {
    condition     = var.grafana_listener_priority >= 1 && var.grafana_listener_priority <= 50000
    error_message = "Listener priority must be between 1 and 50000."
  }
}

# Storage Configuration
variable "enable_persistent_storage" {
  description = "Enable persistent storage using EFS for Prometheus and Grafana"
  type        = bool
  default     = true
}

# Logging Configuration
variable "log_retention_days" {
  description = "Number of days to retain monitoring service logs"
  type        = number
  default     = 3

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

# Metrics Collection Configuration
variable "enable_ecs_discovery" {
  description = "Enable ECS service discovery for Prometheus"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_exporter" {
  description = "Enable CloudWatch metrics exporter for Prometheus"
  type        = bool
  default     = true
}

variable "scrape_intervals" {
  description = "Scrape intervals for different metric types"
  type = object({
    default     = string
    ecs         = string
    cloudwatch  = string
    load_test   = string
  })
  default = {
    default     = "15s"
    ecs         = "30s"
    cloudwatch  = "60s"
    load_test   = "5s"
  }
}

# Load Testing Configuration
variable "enable_load_test_metrics" {
  description = "Enable enhanced metrics collection during load testing"
  type        = bool
  default     = true
}

variable "load_test_dashboard_enabled" {
  description = "Enable load testing specific dashboard"
  type        = bool
  default     = true
}

# Cost Optimization Settings
variable "enable_cost_optimization" {
  description = "Enable cost optimization features (reduced CloudWatch usage)"
  type        = bool
  default     = true
}

variable "cloudwatch_metrics_filter" {
  description = "List of CloudWatch metrics to collect (empty = all)"
  type        = list(string)
  default     = [
    "AWS/ECS/CPUUtilization",
    "AWS/ECS/MemoryUtilization",
    "AWS/ApplicationELB/TargetResponseTime",
    "AWS/ApplicationELB/RequestCount",
    "AWS/ApplicationELB/HTTPCode_Target_2XX_Count",
    "AWS/ApplicationELB/HTTPCode_Target_4XX_Count",
    "AWS/ApplicationELB/HTTPCode_Target_5XX_Count"
  ]
}

# Alerting Configuration
variable "enable_alerting" {
  description = "Enable Prometheus alerting rules"
  type        = bool
  default     = true
}

variable "alert_webhook_url" {
  description = "Webhook URL for sending alerts (Slack, Teams, etc.)"
  type        = string
  default     = null
}

variable "sre_thresholds" {
  description = "SRE alerting thresholds"
  type = object({
    high_cpu_percent      = number
    high_memory_percent   = number
    high_latency_ms      = number
    low_availability_percent = number
    high_error_rate_percent = number
  })
  default = {
    high_cpu_percent      = 80
    high_memory_percent   = 85
    high_latency_ms      = 1000
    low_availability_percent = 99
    high_error_rate_percent = 5
  }
}

# Common Tags
variable "common_tags" {
  description = "Common tags to apply to all monitoring resources"
  type        = map(string)
  default     = {}
}