output "orders_service_repository_url" {
  description = "URL of the orders service ECR repository"
  value       = aws_ecr_repository.orders_service.repository_url
}

output "inventory_service_repository_url" {
  description = "URL of the inventory service ECR repository"
  value       = aws_ecr_repository.inventory_service.repository_url
}

output "prometheus_repository_url" {
  description = "URL of the Prometheus ECR repository"
  value       = aws_ecr_repository.prometheus.repository_url
}

output "grafana_repository_url" {
  description = "URL of the Grafana ECR repository"
  value       = aws_ecr_repository.grafana.repository_url
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.arn
}

output "ecr_repositories" {
  description = "Map of ECR repository URLs"
  value = {
    orders_service    = aws_ecr_repository.orders_service.repository_url
    inventory_service = aws_ecr_repository.inventory_service.repository_url
    prometheus        = aws_ecr_repository.prometheus.repository_url
    grafana          = aws_ecr_repository.grafana.repository_url
  }
}