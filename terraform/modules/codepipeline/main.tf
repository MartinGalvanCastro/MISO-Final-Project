# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.service_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "${var.service_name}-codepipeline-role"
    Service = var.service_name
  })
}

# IAM Policy for CodePipeline
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.service_name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          var.artifacts_bucket_arn,
          "${var.artifacts_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = var.github_connection_arn != null ? var.github_connection_arn : "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.approval_sns_topic_arn != null ? var.approval_sns_topic_arn : "*"
      }
    ]
  })
}

# CloudWatch Log Group for CodePipeline
resource "aws_cloudwatch_log_group" "codepipeline_logs" {
  name              = "/aws/codepipeline/${var.pipeline_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name    = "${var.pipeline_name}-logs"
    Service = var.service_name
  })
}

# CodePipeline
resource "aws_codepipeline" "pipeline" {
  name     = var.pipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = var.artifacts_bucket_name
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = var.github_connection_arn != null ? "CodeStarSourceConnection" : "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = var.github_connection_arn != null ? {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
      } : {
        S3Bucket    = var.artifacts_bucket_name
        S3ObjectKey = "source.zip"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = var.codebuild_project_name
      }
    }
  }

  dynamic "stage" {
    for_each = var.enable_manual_approval ? [1] : []
    content {
      name = "Approval"

      action {
        name     = "ManualApproval"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"

        configuration = var.approval_sns_topic_arn != null ? {
          NotificationArn = var.approval_sns_topic_arn
          CustomData      = "Please review and approve the deployment to ${var.environment}"
        } : {
          CustomData = "Please review and approve the deployment to ${var.environment}"
        }
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName     = var.codedeploy_application_name
        DeploymentGroupName = var.codedeploy_deployment_group
      }
    }
  }

  tags = merge(var.common_tags, {
    Name        = var.pipeline_name
    Service     = var.service_name
    Environment = var.environment
  })
}

# CloudWatch Alarms for pipeline monitoring
resource "aws_cloudwatch_metric_alarm" "pipeline_failure_alarm" {
  alarm_name          = "${var.pipeline_name}-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "PipelineExecutionFailure"
  namespace           = "AWS/CodePipeline"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors pipeline failures for ${var.pipeline_name}"

  dimensions = {
    PipelineName = aws_codepipeline.pipeline.name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.pipeline_name}-failure-alarm"
    Service = var.service_name
  })
}

# EventBridge Rule for pipeline state changes
resource "aws_cloudwatch_event_rule" "pipeline_state_change" {
  name        = "${var.pipeline_name}-state-change"
  description = "Capture pipeline state changes for ${var.pipeline_name}"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = [aws_codepipeline.pipeline.name]
    }
  })

  tags = merge(var.common_tags, {
    Name    = "${var.pipeline_name}-state-change-rule"
    Service = var.service_name
  })
}