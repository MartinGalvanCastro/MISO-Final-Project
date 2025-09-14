variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "create_cluster" {
  description = "Whether to create a new ECS cluster or use existing one"
  type        = bool
  default     = true
}

variable "existing_cluster_id" {
  description = "ID of existing ECS cluster (if create_cluster is false)"
  type        = string
  default     = null
}

variable "existing_cluster_name" {
  description = "Name of existing ECS cluster (if create_cluster is false)"
  type        = string
  default     = null
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

# Task Definition Configuration
variable "container_image" {
  description = "Docker image for the container"
  type        = string
}

variable "container_port" {
  description = "Port on which the container listens"
  type        = number
  default     = 8000
}

variable "cpu" {
  description = "Number of CPU units for the task"
  type        = number
  default     = 256

  validation {
    condition = contains([
      256, 512, 1024, 2048, 4096
    ], var.cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "memory" {
  description = "Amount of memory (MB) for the task"
  type        = number
  default     = 512

  validation {
    condition = contains([
      512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192,
      9216, 10240, 11264, 12288, 13312, 14336, 15360, 16384
    ], var.memory)
    error_message = "Memory must be a valid Fargate memory configuration."
  }
}

variable "platform_version" {
  description = "Fargate platform version"
  type        = string
  default     = "LATEST"
}

# Environment Variables and Secrets
variable "environment_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets for the container (from Parameter Store or Secrets Manager)"
  type        = map(string)
  default     = {}
}

# Health Check Configuration
variable "health_check_command" {
  description = "Health check command for the container"
  type        = list(string)
  default     = null
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_retries" {
  description = "Number of health check retries"
  type        = number
  default     = 3
}

variable "health_check_start_period" {
  description = "Health check start period in seconds"
  type        = number
  default     = 60
}

# Networking Configuration
variable "vpc_id" {
  description = "VPC ID where the service will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS service"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Whether to assign public IP to the tasks"
  type        = bool
  default     = false
}

variable "alb_security_group_ids" {
  description = "List of ALB security group IDs"
  type        = list(string)
  default     = []
}

# Load Balancer Configuration
variable "target_group_arns" {
  description = "List of target group ARNs to associate with the service"
  type        = list(string)
  default     = []
}

# Service Configuration
variable "desired_count" {
  description = "Desired number of running tasks"
  type        = number
  default     = 3
}

variable "deployment_maximum_percent" {
  description = "Maximum percentage of tasks that can be running during deployment"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percentage of tasks during deployment"
  type        = number
  default     = 100
}

variable "enable_deployment_circuit_breaker" {
  description = "Enable deployment circuit breaker"
  type        = bool
  default     = true
}

variable "enable_deployment_rollback" {
  description = "Enable automatic rollback on deployment failure"
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = false
}

# Auto Scaling Configuration
variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 3
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 6
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for auto scaling"
  type        = number
  default     = 70

  validation {
    condition     = var.cpu_target_value > 0 && var.cpu_target_value <= 100
    error_message = "CPU target value must be between 1 and 100."
  }
}

variable "memory_target_value" {
  description = "Target memory utilization percentage for auto scaling"
  type        = number
  default     = 70

  validation {
    condition     = var.memory_target_value > 0 && var.memory_target_value <= 100
    error_message = "Memory target value must be between 1 and 100."
  }
}

variable "scale_in_cooldown" {
  description = "Cooldown period (seconds) after scale in activity"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Cooldown period (seconds) after scale out activity"
  type        = number
  default     = 300
}

# IAM Configuration
variable "task_role_policy_statements" {
  description = "List of IAM policy statements for the task role"
  type = list(object({
    Effect   = string
    Action   = list(string)
    Resource = list(string)
  }))
  default = []
}

# Logging Configuration
variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 14

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

# Monitoring Configuration
variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms for the service"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}