variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for RDS access"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the RDS instance"
  type        = string
  default     = "us-east-1a"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"  # Free tier eligible
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20  # Free tier: 20GB
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "medisupply"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 0  # Disable backups for cost savings
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false  # Set to false for development
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting"
  type        = bool
  default     = true  # Set to true for development
}