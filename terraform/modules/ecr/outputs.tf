output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.repository.arn
}

output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.repository.repository_url
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.repository.name
}

output "repository_registry_id" {
  description = "Registry ID of the ECR repository"
  value       = aws_ecr_repository.repository.registry_id
}

output "repository_repository_url" {
  description = "Repository URL of the ECR repository"
  value       = aws_ecr_repository.repository.repository_url
}

output "lifecycle_policy_text" {
  description = "The text of the lifecycle policy"
  value       = var.enable_lifecycle_policy ? aws_ecr_lifecycle_policy.policy[0].policy : null
}

output "repository_info" {
  description = "Complete repository information"
  value = {
    arn          = aws_ecr_repository.repository.arn
    name         = aws_ecr_repository.repository.name
    registry_id  = aws_ecr_repository.repository.registry_id
    url          = aws_ecr_repository.repository.repository_url
    service_name = var.service_name
  }
}