variable "project_name" {
  description = "Name of the CodeBuild project"
  type        = string
}

variable "service_name" {
  description = "Name of the service this CodeBuild project is for"
  type        = string
}

variable "description" {
  description = "Description of the CodeBuild project"
  type        = string
  default     = "CodeBuild project for CI/CD pipeline"
}

# ECR Configuration
variable "ecr_repository_arn" {
  description = "ARN of the ECR repository to push images to"
  type        = string
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository to push images to"
  type        = string
}

# Build Configuration
variable "compute_type" {
  description = "Information about the compute resources the build project will use"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"

  validation {
    condition = contains([
      "BUILD_GENERAL1_SMALL",
      "BUILD_GENERAL1_MEDIUM",
      "BUILD_GENERAL1_LARGE",
      "BUILD_GENERAL1_2XLARGE"
    ], var.compute_type)
    error_message = "Compute type must be a valid CodeBuild compute type."
  }
}

variable "build_image" {
  description = "Docker image to use for this build project"
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
}

variable "image_pull_credentials_type" {
  description = "Type of credentials AWS CodeBuild uses to pull images in your build environment"
  type        = string
  default     = "CODEBUILD"

  validation {
    condition     = contains(["CODEBUILD", "SERVICE_ROLE"], var.image_pull_credentials_type)
    error_message = "Image pull credentials type must be either CODEBUILD or SERVICE_ROLE."
  }
}

variable "privileged_mode" {
  description = "Whether to enable running the Docker daemon inside a Docker container"
  type        = bool
  default     = true
}

variable "default_image_tag" {
  description = "Default image tag to use when building images"
  type        = string
  default     = "latest"
}

# Source Configuration
variable "source_type" {
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
    ], var.source_type)
    error_message = "Source type must be a valid CodeBuild source type."
  }
}

variable "source_location" {
  description = "Location of the source code from git or s3"
  type        = string
  default     = null
}

variable "source_version" {
  description = "Version of the build input to be built for this project"
  type        = string
  default     = null
}

variable "git_clone_depth" {
  description = "Truncate git history to this many commits"
  type        = number
  default     = 1
}

variable "buildspec_file" {
  description = "Build specification to use for this build project's related builds"
  type        = string
  default     = null
}

variable "dockerfile_path" {
  description = "Path to the Dockerfile relative to the source root"
  type        = string
  default     = "."
}

# Environment Variables
variable "environment_variables" {
  description = "A map of environment variables to make available to the build environment"
  type        = map(string)
  default     = {}
}

# Artifacts Configuration
variable "artifacts_type" {
  description = "Build output artifact's type"
  type        = string
  default     = "NO_ARTIFACTS"

  validation {
    condition = contains([
      "CODEPIPELINE",
      "NO_ARTIFACTS",
      "S3"
    ], var.artifacts_type)
    error_message = "Artifacts type must be a valid CodeBuild artifacts type."
  }
}

variable "artifacts_location" {
  description = "Information about the build output artifact location"
  type        = string
  default     = null
}

variable "artifacts_bucket_arn" {
  description = "ARN of the S3 bucket for build artifacts"
  type        = string
  default     = null
}

# VPC Configuration
variable "vpc_id" {
  description = "ID of the VPC within which to run builds"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs within which to run builds"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs to assign to running builds"
  type        = list(string)
  default     = []
}

# Logging Configuration
variable "log_retention_days" {
  description = "Number of days to retain build logs"
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
variable "enable_build_failure_alarm" {
  description = "Enable CloudWatch alarm for build failures"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

# Webhook Configuration
variable "enable_webhook" {
  description = "Enable GitHub webhook for automatic builds"
  type        = bool
  default     = true
}

variable "service_path_filter" {
  description = "Path filter for webhook to trigger builds only when specific service directory changes"
  type        = string
  default     = null
}

variable "webhook_branch_filter" {
  description = "Branch filter for webhook (e.g., '^refs/heads/main$')"
  type        = string
  default     = "^refs/heads/main$"
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}