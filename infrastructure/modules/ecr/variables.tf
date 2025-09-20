variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
  default     = "*/*"  # Allow any repository for now, can be restricted later
}