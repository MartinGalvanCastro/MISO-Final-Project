variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "service_name" {
  description = "Name of the service this repository is for"
  type        = string
}

variable "description" {
  description = "Description of the ECR repository"
  type        = string
  default     = "Container repository"
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "enable_lifecycle_policy" {
  description = "Enable lifecycle policy for the repository"
  type        = bool
  default     = true
}

variable "keep_versioned_images" {
  description = "Number of versioned images to keep"
  type        = number
  default     = 3
}

variable "keep_latest_images" {
  description = "Number of latest tagged images to keep"
  type        = number
  default     = 1
}

variable "untagged_expiry_days" {
  description = "Number of days after which untagged images expire"
  type        = number
  default     = 1
}

variable "version_tag_prefixes" {
  description = "List of tag prefixes for versioned images"
  type        = list(string)
  default     = ["v"]
}

variable "latest_tag_prefixes" {
  description = "List of tag prefixes for latest images"
  type        = list(string)
  default     = ["latest"]
}

variable "repository_policy" {
  description = "JSON policy document for repository access"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}