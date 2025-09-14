# ECR Repository
resource "aws_ecr_repository" "repository" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = merge(var.common_tags, {
    Name        = var.repository_name
    Service     = var.service_name
    Description = var.description
  })
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "policy" {
  count      = var.enable_lifecycle_policy ? 1 : 0
  repository = aws_ecr_repository.repository.name

  policy = jsonencode({
    rules = concat(
      var.keep_versioned_images > 0 ? [
        {
          rulePriority = 1
          description  = "Keep last ${var.keep_versioned_images} versioned images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = var.version_tag_prefixes
            countType     = "imageCountMoreThan"
            countNumber   = var.keep_versioned_images
          }
          action = {
            type = "expire"
          }
        }
      ] : [],
      var.keep_latest_images > 0 ? [
        {
          rulePriority = 2
          description  = "Keep ${var.keep_latest_images} latest tagged images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = var.latest_tag_prefixes
            countType     = "imageCountMoreThan"
            countNumber   = var.keep_latest_images
          }
          action = {
            type = "expire"
          }
        }
      ] : [],
      var.untagged_expiry_days > 0 ? [
        {
          rulePriority = 3
          description  = "Delete untagged images older than ${var.untagged_expiry_days} days"
          selection = {
            tagStatus   = "untagged"
            countType   = "sinceImagePushed"
            countUnit   = "days"
            countNumber = var.untagged_expiry_days
          }
          action = {
            type = "expire"
          }
        }
      ] : []
    )
  })
}

# ECR Repository Policy (for cross-account access if needed)
resource "aws_ecr_repository_policy" "repository_policy" {
  count      = var.repository_policy != null ? 1 : 0
  repository = aws_ecr_repository.repository.name
  policy     = var.repository_policy
}