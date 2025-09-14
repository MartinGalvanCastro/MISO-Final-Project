variable "pipeline_name" {
  description = "Name of the CodePipeline"
  type        = string
}

variable "service_name" {
  description = "Name of the service for tagging"
  type        = string
}

# Source Configuration
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to monitor"
  type        = string
  default     = "main"
}

variable "github_connection_arn" {
  description = "ARN of GitHub connection for CodeStar"
  type        = string
  default     = null
}

# Build Configuration
variable "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  type        = string
}

# Deploy Configuration
variable "codedeploy_application_name" {
  description = "Name of the CodeDeploy application"
  type        = string
}

variable "codedeploy_deployment_group" {
  description = "Name of the CodeDeploy deployment group"
  type        = string
}

# Artifacts Configuration
variable "artifacts_bucket_name" {
  description = "S3 bucket for pipeline artifacts"
  type        = string
}

variable "artifacts_bucket_arn" {
  description = "ARN of S3 bucket for pipeline artifacts"
  type        = string
}

# Pipeline Configuration
variable "enable_manual_approval" {
  description = "Enable manual approval before deployment"
  type        = bool
  default     = false
}

variable "approval_sns_topic_arn" {
  description = "SNS topic ARN for approval notifications"
  type        = string
  default     = null
}

# Environment Configuration
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Logging Configuration
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}