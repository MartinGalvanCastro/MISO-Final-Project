# Application Configuration
variable "application_name" {
  description = "Name of the CodeDeploy application"
  type        = string
}

variable "service_name" {
  description = "Name of the service being deployed"
  type        = string
}

variable "deployment_group_name" {
  description = "Name of the CodeDeploy deployment group"
  type        = string
  default     = "default"
}

# ECS Configuration
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

# Load Balancer Configuration
variable "target_group_name" {
  description = "Name of the target group (deprecated - use blue/green target groups)"
  type        = string
  default     = ""
}

variable "blue_target_group_name" {
  description = "Name of the blue target group for blue-green deployment"
  type        = string
}

variable "green_target_group_name" {
  description = "Name of the green target group for blue-green deployment"
  type        = string
}

variable "listener_arn" {
  description = "ARN of the ALB listener for blue-green deployment"
  type        = string
}

# Blue-Green Deployment Configuration
variable "termination_wait_time_minutes" {
  description = "Time in minutes to wait before terminating blue instances"
  type        = number
  default     = 5
}

variable "deployment_ready_action" {
  description = "Action to take when deployment is ready (CONTINUE_DEPLOYMENT or STOP_DEPLOYMENT)"
  type        = string
  default     = "CONTINUE_DEPLOYMENT"
}

variable "deployment_ready_wait_time_minutes" {
  description = "Time in minutes to wait for deployment ready signal"
  type        = number
  default     = 0
}

# Auto Rollback Configuration
variable "auto_rollback_enabled" {
  description = "Enable automatic rollback on deployment failure"
  type        = bool
  default     = true
}

variable "auto_rollback_events" {
  description = "Events that trigger automatic rollback"
  type        = list(string)
  default     = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
}

# ECR Integration for Auto-deployment
variable "enable_auto_deployment" {
  description = "Enable automatic deployment on ECR image push"
  type        = bool
  default     = true
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository to watch for image pushes"
  type        = string
}

variable "ecr_trigger_tags" {
  description = "List of ECR image tags that trigger deployment"
  type        = list(string)
  default     = ["latest", "stable"]
}

# Notification Configuration
variable "trigger_configurations" {
  description = "List of trigger configurations for deployment notifications"
  type = list(object({
    trigger_events     = list(string)
    trigger_name       = string
    trigger_target_arn = string
  }))
  default = []
}

# Logging Configuration
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

# Common Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}