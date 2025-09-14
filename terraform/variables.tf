# General Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "medisupply"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "medisupply"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

# ECR Repository Names
variable "orders_service_repo_name" {
  description = "Name for the orders service ECR repository"
  type        = string
  default     = "medisupply/orders-service"
}

variable "inventory_service_repo_name" {
  description = "Name for the inventory service ECR repository"
  type        = string
  default     = "medisupply/inventory-service"
}

# ECR Configuration
variable "ecr_image_tag_mutability" {
  description = "The tag mutability setting for ECR repositories. Must be one of: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "ecr_scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

# ECR Lifecycle Policy Configuration
variable "ecr_keep_versioned_images" {
  description = "Number of versioned images to keep in ECR repositories"
  type        = number
  default     = 3

  validation {
    condition     = var.ecr_keep_versioned_images >= 0
    error_message = "Number of versioned images to keep must be non-negative."
  }
}

variable "ecr_keep_latest_images" {
  description = "Number of latest tagged images to keep in ECR repositories"
  type        = number
  default     = 1

  validation {
    condition     = var.ecr_keep_latest_images >= 0
    error_message = "Number of latest images to keep must be non-negative."
  }
}

variable "ecr_untagged_expiry_days" {
  description = "Number of days after which untagged images expire in ECR repositories"
  type        = number
  default     = 1

  validation {
    condition     = var.ecr_untagged_expiry_days >= 0
    error_message = "Untagged expiry days must be non-negative."
  }
}

# SQS Queue Names
variable "orders_queue_name" {
  description = "Name for the orders service SQS queue"
  type        = string
  default     = "orders-queue"
}

# SQS Configuration
variable "sqs_visibility_timeout_seconds" {
  description = "The visibility timeout for SQS queues"
  type        = number
  default     = 300

  validation {
    condition     = var.sqs_visibility_timeout_seconds >= 0 && var.sqs_visibility_timeout_seconds <= 43200
    error_message = "Visibility timeout must be between 0 and 43200 seconds (12 hours)."
  }
}

variable "sqs_message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message"
  type        = number
  default     = 1209600 # 14 days

  validation {
    condition     = var.sqs_message_retention_seconds >= 60 && var.sqs_message_retention_seconds <= 1209600
    error_message = "Message retention must be between 60 seconds and 1209600 seconds (14 days)."
  }
}

variable "sqs_receive_wait_time_seconds" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive (long polling)"
  type        = number
  default     = 20

  validation {
    condition     = var.sqs_receive_wait_time_seconds >= 0 && var.sqs_receive_wait_time_seconds <= 20
    error_message = "Receive wait time must be between 0 and 20 seconds."
  }
}

variable "sqs_max_message_size" {
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it"
  type        = number
  default     = 262144

  validation {
    condition     = var.sqs_max_message_size >= 1024 && var.sqs_max_message_size <= 262144
    error_message = "Max message size must be between 1024 and 262144 bytes."
  }
}

# SQS Dead Letter Queue Configuration (Optional - not used for orders service)
variable "sqs_enable_dead_letter_queue" {
  description = "Enable dead letter queue for SQS queues (not needed for event publishing)"
  type        = bool
  default     = false
}

variable "sqs_max_receive_count" {
  description = "The number of times a message is delivered to the source queue before being moved to the dead-letter queue"
  type        = number
  default     = 3

  validation {
    condition     = var.sqs_max_receive_count >= 1 && var.sqs_max_receive_count <= 1000
    error_message = "Max receive count must be between 1 and 1000."
  }
}

# SQS Monitoring Configuration
variable "sqs_enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms for SQS queue monitoring"
  type        = bool
  default     = true
}

variable "sqs_queue_depth_alarm_threshold" {
  description = "Threshold for SQS queue depth alarm"
  type        = number
  default     = 100

  validation {
    condition     = var.sqs_queue_depth_alarm_threshold >= 1
    error_message = "Queue depth alarm threshold must be at least 1."
  }
}

variable "sqs_dlq_depth_alarm_threshold" {
  description = "Threshold for SQS dead letter queue depth alarm (not used for orders service)"
  type        = number
  default     = 1

  validation {
    condition     = var.sqs_dlq_depth_alarm_threshold >= 1
    error_message = "DLQ depth alarm threshold must be at least 1."
  }
}

# SQS Encryption Configuration
variable "sqs_kms_master_key_id" {
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK"
  type        = string
  default     = null
}

# CodeBuild Configuration
variable "codebuild_compute_type" {
  description = "Information about the compute resources the build project will use"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"

  validation {
    condition = contains([
      "BUILD_GENERAL1_SMALL",
      "BUILD_GENERAL1_MEDIUM",
      "BUILD_GENERAL1_LARGE",
      "BUILD_GENERAL1_2XLARGE"
    ], var.codebuild_compute_type)
    error_message = "Compute type must be a valid CodeBuild compute type."
  }
}

variable "codebuild_image" {
  description = "Docker image to use for CodeBuild projects"
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
}

variable "codebuild_source_type" {
  description = "Type of repository that contains the source code to be built"
  type        = string
  default     = "GITHUB"

  validation {
    condition = contains([
      "CODECOMMIT",
      "CODEPIPELINE",
      "GITHUB",
      "GITHUB_ENTERPRISE",
      "BITBUCKET",
      "S3",
      "NO_SOURCE"
    ], var.codebuild_source_type)
    error_message = "Source type must be a valid CodeBuild source type."
  }
}

variable "orders_service_source_location" {
  description = "Location of the orders service source code repository"
  type        = string
  default     = "https://github.com/your-org/your-repo.git"
}

variable "inventory_service_source_location" {
  description = "Location of the inventory service source code repository"
  type        = string
  default     = "https://github.com/your-org/your-repo.git"
}

variable "orders_service_version_tag" {
  description = "Version tag for orders service images"
  type        = string
  default     = "v1.0.0"
}

variable "inventory_service_version_tag" {
  description = "Version tag for inventory service images"
  type        = string
  default     = "v1.0.0"
}

variable "codebuild_environment_variables" {
  description = "A map of environment variables to make available to all CodeBuild projects"
  type        = map(string)
  default     = {}
}

variable "codebuild_log_retention_days" {
  description = "Number of days to retain CodeBuild logs"
  type        = number
  default     = 7  # Reduced for cost savings

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.codebuild_log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "codebuild_enable_alarms" {
  description = "Enable CloudWatch alarms for CodeBuild build failures"
  type        = bool
  default     = true
}

# VPC Configuration
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2

  validation {
    condition     = var.public_subnet_count >= 2
    error_message = "At least 2 public subnets are required for ALB."
  }
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2

  validation {
    condition     = var.private_subnet_count >= 2
    error_message = "At least 2 private subnets are required for ECS services."
  }
}

variable "create_nat_gateways" {
  description = "Create NAT gateways for private subnets"
  type        = bool
  default     = true
}

variable "create_s3_endpoint" {
  description = "Create VPC endpoint for S3"
  type        = bool
  default     = true
}

# ALB Configuration
variable "alb_enable_deletion_protection" {
  description = "Enable deletion protection for the ALB"
  type        = bool
  default     = false
}

variable "alb_idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "alb_enable_access_logs" {
  description = "Enable access logs for the ALB"
  type        = bool
  default     = false
}

variable "alb_access_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  type        = string
  default     = null
}

variable "alb_enable_https" {
  description = "Enable HTTPS listener for the ALB"
  type        = bool
  default     = false
}

variable "alb_certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener"
  type        = string
  default     = null
}

# ECS Configuration - Orders Service
variable "ecs_orders_cpu" {
  description = "Number of CPU units for orders service tasks"
  type        = number
  default     = 256

  validation {
    condition = contains([
      256, 512, 1024, 2048, 4096
    ], var.ecs_orders_cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "ecs_orders_memory" {
  description = "Amount of memory (MB) for orders service tasks"
  type        = number
  default     = 512

  validation {
    condition = contains([
      512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192,
      9216, 10240, 11264, 12288, 13312, 14336, 15360, 16384
    ], var.ecs_orders_memory)
    error_message = "Memory must be a valid Fargate memory configuration."
  }
}

variable "ecs_orders_secrets" {
  description = "Secrets for the orders service container (from Parameter Store or Secrets Manager)"
  type        = map(string)
  default     = {}
}

# ECS Configuration - Inventory Service
variable "ecs_inventory_cpu" {
  description = "Number of CPU units for inventory service tasks"
  type        = number
  default     = 256

  validation {
    condition = contains([
      256, 512, 1024, 2048, 4096
    ], var.ecs_inventory_cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "ecs_inventory_memory" {
  description = "Amount of memory (MB) for inventory service tasks"
  type        = number
  default     = 512

  validation {
    condition = contains([
      512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192,
      9216, 10240, 11264, 12288, 13312, 14336, 15360, 16384
    ], var.ecs_inventory_memory)
    error_message = "Memory must be a valid Fargate memory configuration."
  }
}

variable "ecs_inventory_secrets" {
  description = "Secrets for the inventory service container (from Parameter Store or Secrets Manager)"
  type        = map(string)
  default     = {}
}

# ECS Auto Scaling Configuration
variable "ecs_cpu_target_value" {
  description = "Target CPU utilization percentage for auto scaling"
  type        = number
  default     = 70

  validation {
    condition     = var.ecs_cpu_target_value > 0 && var.ecs_cpu_target_value <= 100
    error_message = "CPU target value must be between 1 and 100."
  }
}

variable "ecs_memory_target_value" {
  description = "Target memory utilization percentage for auto scaling"
  type        = number
  default     = 70

  validation {
    condition     = var.ecs_memory_target_value > 0 && var.ecs_memory_target_value <= 100
    error_message = "Memory target value must be between 1 and 100."
  }
}

# ECS Logging Configuration
variable "ecs_log_retention_days" {
  description = "Number of days to retain ECS service logs"
  type        = number
  default     = 3  # Reduced for cost savings

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.ecs_log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

# ECS Monitoring Configuration
variable "ecs_enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms for ECS services"
  type        = bool
  default     = true
}

# CodeDeploy Configuration
variable "enable_blue_green_deployment" {
  description = "Enable blue-green deployment with CodeDeploy"
  type        = bool
  default     = true
}

variable "codedeploy_termination_wait_time_minutes" {
  description = "Time in minutes to wait before terminating blue instances"
  type        = number
  default     = 5

  validation {
    condition     = var.codedeploy_termination_wait_time_minutes >= 0 && var.codedeploy_termination_wait_time_minutes <= 2880
    error_message = "Termination wait time must be between 0 and 2880 minutes (48 hours)."
  }
}

variable "codedeploy_auto_rollback_enabled" {
  description = "Enable automatic rollback on deployment failure"
  type        = bool
  default     = true
}

variable "codedeploy_enable_auto_deployment" {
  description = "Enable automatic deployment on ECR image push"
  type        = bool
  default     = true
}

variable "codedeploy_ecr_trigger_tags" {
  description = "List of ECR image tags that trigger deployment"
  type        = list(string)
  default     = ["latest", "stable"]
}

variable "codedeploy_log_retention_days" {
  description = "Number of days to retain CodeDeploy logs"
  type        = number
  default     = 7  # Reduced for cost savings

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.codedeploy_log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

# Monitoring Configuration
variable "enable_sre_monitoring" {
  description = "Enable comprehensive SRE monitoring with Prometheus and Grafana"
  type        = bool
  default     = true
}

variable "monitoring_log_retention_days" {
  description = "Number of days to retain monitoring service logs (reduced for cost savings)"
  type        = number
  default     = 3

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.monitoring_log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "prometheus_retention_days" {
  description = "Number of days to retain Prometheus metrics (local storage)"
  type        = number
  default     = 15

  validation {
    condition     = var.prometheus_retention_days >= 1 && var.prometheus_retention_days <= 365
    error_message = "Prometheus retention must be between 1 and 365 days."
  }
}

variable "enable_persistent_monitoring_storage" {
  description = "Enable persistent EFS storage for monitoring data"
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana dashboard"
  type        = string
  default     = "admin123!"
  sensitive   = true
}

# Cost Optimization Settings
variable "enable_cost_optimized_logging" {
  description = "Enable cost optimization for logging (reduced retention periods)"
  type        = bool
  default     = true
}

# Database Configuration
variable "database_password" {
  description = "Password for the RDS PostgreSQL database"
  type        = string
  sensitive   = true
}