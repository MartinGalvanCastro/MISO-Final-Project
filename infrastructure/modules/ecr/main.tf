# ECR Repository for Orders Service
resource "aws_ecr_repository" "orders_service" {
  name                 = "${var.project_name}/orders-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false  # Disabled to stay in free tier
  }

  tags = {
    Name        = "${var.project_name}-orders-service-ecr"
    Service     = "orders-service"
    Description = "Container repository for orders microservice"
  }
}

# ECR Repository for Inventory Service
resource "aws_ecr_repository" "inventory_service" {
  name                 = "${var.project_name}/inventory-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false  # Disabled to stay in free tier
  }

  tags = {
    Name        = "${var.project_name}-inventory-service-ecr"
    Service     = "inventory-service"
    Description = "Container repository for inventory microservice"
  }
}

# ECR Repository for Grafana
resource "aws_ecr_repository" "grafana" {
  name                 = "${var.project_name}/grafana"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false  # Disabled to stay in free tier
  }

  tags = {
    Name        = "${var.project_name}-grafana-ecr"
    Service     = "grafana"
    Description = "Container repository for Grafana dashboards"
  }
}

# ECR Repository for Prometheus
resource "aws_ecr_repository" "prometheus" {
  name                 = "${var.project_name}/prometheus"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false  # Disabled to stay in free tier
  }

  tags = {
    Name        = "${var.project_name}-prometheus-ecr"
    Service     = "prometheus"
    Description = "Container repository for Prometheus monitoring"
  }
}


# Lifecycle Policy for Orders Service
resource "aws_ecr_lifecycle_policy" "orders_service" {
  repository = aws_ecr_repository.orders_service.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Lifecycle Policy for Inventory Service
resource "aws_ecr_lifecycle_policy" "inventory_service" {
  repository = aws_ecr_repository.inventory_service.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Lifecycle Policy for Grafana
resource "aws_ecr_lifecycle_policy" "grafana" {
  repository = aws_ecr_repository.grafana.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Lifecycle Policy for Prometheus
resource "aws_ecr_lifecycle_policy" "prometheus" {
  repository = aws_ecr_repository.prometheus.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}


# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-github-actions-role"
    Description = "IAM role for GitHub Actions CI/CD"
  }
}

# IAM Policy for ECR Access
resource "aws_iam_policy" "github_actions_ecr" {
  name        = "${var.project_name}-github-actions-ecr-policy"
  description = "IAM policy for GitHub Actions ECR access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for ECS Access (for deployment)
resource "aws_iam_policy" "github_actions_ecs" {
  name        = "${var.project_name}-github-actions-ecs-policy"
  description = "IAM policy for GitHub Actions ECS deployment"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"
      }
    ]
  })
}

# IAM Policy for CodeDeploy Access (for Blue/Green deployment)
resource "aws_iam_policy" "github_actions_codedeploy" {
  name        = "${var.project_name}-github-actions-codedeploy-policy"
  description = "IAM policy for GitHub Actions CodeDeploy Blue/Green deployment"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:StopDeployment"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:CreateTaskSet",
          "ecs:UpdateTaskSet",
          "ecs:DescribeTaskSets",
          "ecs:DeleteTaskSet"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:ModifyRule"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach ECR Policy to GitHub Actions Role
resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ecr.arn
}

# Attach ECS Policy to GitHub Actions Role
resource "aws_iam_role_policy_attachment" "github_actions_ecs" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ecs.arn
}

# Attach CodeDeploy Policy to GitHub Actions Role
resource "aws_iam_role_policy_attachment" "github_actions_codedeploy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_codedeploy.arn
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}