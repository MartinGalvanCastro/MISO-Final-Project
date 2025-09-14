# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-codebuild-role"
    Service     = var.service_name
    Description = "IAM role for CodeBuild project"
  })
}

# IAM Policy for CodeBuild
resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.project_name}-codebuild-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.project_name}*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage"
        ]
        Resource = var.ecr_repository_arn
      }
    ], var.artifacts_bucket_arn != null ? [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          "${var.artifacts_bucket_arn}/*"
        ]
      }
    ] : [])
  })
}

# CloudWatch Log Group for CodeBuild
resource "aws_cloudwatch_log_group" "codebuild_logs" {
  name              = "/aws/codebuild/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-codebuild-logs"
    Service     = var.service_name
    Description = "CloudWatch log group for CodeBuild project"
  })
}

# CodeBuild Project
resource "aws_codebuild_project" "project" {
  name          = var.project_name
  description   = var.description
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type     = var.artifacts_type
    location = var.artifacts_type == "S3" ? var.artifacts_location : null
  }

  environment {
    compute_type                = var.compute_type
    image                      = var.build_image
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = var.image_pull_credentials_type
    privileged_mode            = var.privileged_mode

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = var.ecr_repository_url
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = var.default_image_tag
    }

    dynamic "environment_variable" {
      for_each = var.environment_variables
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PLAINTEXT"
      }
    }
  }

  source {
    type            = var.source_type
    location        = var.source_type == "GITHUB" ? var.source_location : null
    git_clone_depth = var.source_type == "GITHUB" ? var.git_clone_depth : null

    buildspec = var.buildspec_file != null ? var.buildspec_file : templatefile("${path.module}/templates/buildspec.yml", {
      service_name = var.service_name
      dockerfile_path = var.dockerfile_path
    })
  }

  source_version = var.source_version

  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = aws_cloudwatch_log_group.codebuild_logs.name
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_id != null ? [1] : []
    content {
      vpc_id = var.vpc_id
      subnets = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  tags = merge(var.common_tags, {
    Name        = var.project_name
    Service     = var.service_name
    Description = var.description
  })
}

# GitHub Webhook for automatic builds
resource "aws_codebuild_webhook" "github_webhook" {
  count        = var.source_type == "GITHUB" && var.enable_webhook ? 1 : 0
  project_name = aws_codebuild_project.project.name

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    # Filter for the main branch only
    filter {
      type    = "HEAD_REF"
      pattern = "^refs/heads/main$"
    }
  }
}

# CloudWatch Alarms for monitoring build failures
resource "aws_cloudwatch_metric_alarm" "build_failure_alarm" {
  count = var.enable_build_failure_alarm ? 1 : 0

  alarm_name          = "${var.project_name}-build-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FailedBuilds"
  namespace           = "AWS/CodeBuild"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors build failures for ${var.project_name}"
  alarm_actions       = var.alarm_actions

  dimensions = {
    ProjectName = aws_codebuild_project.project.name
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-build-failure-alarm"
    Service     = var.service_name
    Description = "CloudWatch alarm for CodeBuild failures"
  })
}