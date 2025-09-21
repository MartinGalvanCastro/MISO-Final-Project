# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"  # Enable for monitoring dashboards
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Project     = var.project_name
    Environment = var.environment
  }
}


# CloudWatch Log Groups for each service
resource "aws_cloudwatch_log_group" "orders_service" {
  name              = "/ecs/${var.project_name}/orders-service"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-orders-logs"
    Project     = var.project_name
    Environment = var.environment
    Service     = "orders-service"
  }
}

resource "aws_cloudwatch_log_group" "inventory_service" {
  name              = "/ecs/${var.project_name}/inventory-service"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-inventory-logs"
    Project     = var.project_name
    Environment = var.environment
    Service     = "inventory-service"
  }
}

resource "aws_cloudwatch_log_group" "prometheus" {
  name              = "/ecs/${var.project_name}/prometheus"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-prometheus-logs"
    Project     = var.project_name
    Environment = var.environment
    Service     = "prometheus"
  }
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/${var.project_name}/grafana"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-grafana-logs"
    Project     = var.project_name
    Environment = var.environment
    Service     = "grafana"
  }
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Attach basic ECS task execution policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for accessing Secrets Manager
resource "aws_iam_policy" "ecs_secrets_policy" {
  name        = "${var.project_name}-ecs-secrets-policy"
  description = "Policy for ECS tasks to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.db_secret_arn,
          var.database_url_secret_arn
        ]
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Attach secrets policy to execution role
resource "aws_iam_role_policy_attachment" "ecs_secrets_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}

# Additional policy for ECR access
resource "aws_iam_policy" "ecs_ecr_policy" {
  name        = "${var.project_name}-ecs-ecr-policy"
  description = "Policy for ECS tasks to access ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# PassRole policy for ECS task execution role to pass task roles
resource "aws_iam_policy" "ecs_pass_role_policy" {
  name        = "${var.project_name}-ecs-pass-role-policy"
  description = "Policy for ECS task execution role to pass task roles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_task_role.arn,
          aws_iam_role.ecs_task_execution_role.arn
        ]
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Attach ECR policy to execution role
resource "aws_iam_role_policy_attachment" "ecs_ecr_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_ecr_policy.arn
}

# Attach PassRole policy to execution role
resource "aws_iam_role_policy_attachment" "ecs_pass_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_pass_role_policy.arn
}

# ECS Task Role (for application permissions)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Attach SQS policy to task role
resource "aws_iam_role_policy_attachment" "ecs_task_sqs_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = var.sqs_access_policy_arn
}

# CloudWatch policy for Grafana
resource "aws_iam_policy" "ecs_cloudwatch_policy" {
  name        = "${var.project_name}-ecs-cloudwatch-policy"
  description = "Policy for ECS tasks to access CloudWatch metrics"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "ec2:DescribeRegions",
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:ListClusters",
          "ecs:ListServices",
          "ecs:ListTasks",
          "oam:ListSinks",
          "oam:ListAttachedLinks"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Attach CloudWatch policy to task role
resource "aws_iam_role_policy_attachment" "ecs_task_cloudwatch_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_cloudwatch_policy.arn
}