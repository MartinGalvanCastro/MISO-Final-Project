# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# CodeDeploy Application
resource "aws_codedeploy_app" "app" {
  compute_platform = "ECS"
  name             = var.application_name

  tags = merge(var.common_tags, {
    Name        = var.application_name
    Service     = var.service_name
    Description = "CodeDeploy application for ${var.service_name}"
  })
}

# IAM Role for CodeDeploy
resource "aws_iam_role" "codedeploy_role" {
  name = "${var.application_name}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "${var.application_name}-codedeploy-role"
    Service = var.service_name
  })
}

# Attach AWS managed policy for ECS CodeDeploy
resource "aws_iam_role_policy_attachment" "codedeploy_role_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# Additional IAM policy for ECS and ALB permissions
resource "aws_iam_role_policy" "codedeploy_additional_policy" {
  name = "${var.application_name}-codedeploy-additional-policy"
  role = aws_iam_role.codedeploy_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:CreateTaskSet",
          "ecs:DeleteTaskSet",
          "ecs:DescribeServices",
          "ecs:UpdateServicePrimaryTaskSet",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:ModifyRule",
          "lambda:InvokeFunction",
          "cloudwatch:DescribeAlarms",
          "sns:Publish",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = var.ecs_task_role_arn
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = var.ecs_execution_role_arn
      }
    ]
  })
}

# CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "deployment_group" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = var.deployment_group_name
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  auto_rollback_configuration {
    enabled = var.auto_rollback_enabled
    events  = var.auto_rollback_events
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                         = "TERMINATE"
      termination_wait_time_in_minutes = var.termination_wait_time_minutes
    }

    deployment_ready_option {
      action_on_timeout = var.deployment_ready_action
      wait_time_in_minutes = var.deployment_ready_wait_time_minutes
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_service_name
  }

  load_balancer_info {
    target_group_info {
      name = var.target_group_name
    }
  }

  dynamic "trigger_configuration" {
    for_each = var.trigger_configurations
    content {
      trigger_events     = trigger_configuration.value.trigger_events
      trigger_name       = trigger_configuration.value.trigger_name
      trigger_target_arn = trigger_configuration.value.trigger_target_arn
    }
  }

  tags = merge(var.common_tags, {
    Name    = "${var.application_name}-deployment-group"
    Service = var.service_name
  })
}

# CodeDeploy Deployment Configuration for Linear Blue-Green with 10-minute deployment
resource "aws_codedeploy_deployment_config" "linear_10_percent" {
  deployment_config_name = "${var.application_name}-Linear10PercentEvery1MinuteFor10Minutes"
  compute_platform       = "ECS"

  traffic_routing_config {
    type = "TimeBasedLinear"

    time_based_linear {
      linear_percentage = 10
      linear_interval   = 1
    }
  }

  tags = merge(var.common_tags, {
    Name    = "${var.application_name}-linear-deployment-config"
    Service = var.service_name
  })
}

# EventBridge Rule for ECR Image Push
resource "aws_cloudwatch_event_rule" "ecr_push_rule" {
  count = var.enable_auto_deployment ? 1 : 0

  name        = "${var.application_name}-ecr-push-rule"
  description = "Trigger CodeDeploy when new image is pushed to ECR"

  event_pattern = jsonencode({
    source      = ["aws.ecr"]
    detail-type = ["ECR Image Action"]
    detail = {
      action-type   = ["PUSH"]
      image-tag     = var.ecr_trigger_tags
      repository-name = [var.ecr_repository_name]
      result        = ["SUCCESS"]
    }
  })

  tags = merge(var.common_tags, {
    Name    = "${var.application_name}-ecr-push-rule"
    Service = var.service_name
  })
}

# EventBridge Target for CodeDeploy
resource "aws_cloudwatch_event_target" "codedeploy_target" {
  count = var.enable_auto_deployment ? 1 : 0

  rule      = aws_cloudwatch_event_rule.ecr_push_rule[0].name
  target_id = "CodeDeployTarget"
  arn       = "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:application:${aws_codedeploy_app.app.name}"

  role_arn = aws_iam_role.eventbridge_role[0].arn

  input_transformer {
    input_paths = {
      repository = "$.detail.repository-name"
      tag        = "$.detail.image-tag"
    }

    input_template = jsonencode({
      applicationName     = aws_codedeploy_app.app.name
      deploymentGroupName = aws_codedeploy_deployment_group.deployment_group.deployment_group_name
      revision = {
        revisionType = "Image"
        imageRevision = {
          imageTag = "<tag>"
        }
      }
      deploymentConfigName = aws_codedeploy_deployment_config.linear_10_percent.deployment_config_name
      description         = "Auto-deployment triggered by ECR push"
    })
  }
}

# IAM Role for EventBridge to trigger CodeDeploy
resource "aws_iam_role" "eventbridge_role" {
  count = var.enable_auto_deployment ? 1 : 0

  name = "${var.application_name}-eventbridge-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "${var.application_name}-eventbridge-role"
    Service = var.service_name
  })
}

# IAM Policy for EventBridge to start CodeDeploy deployments
resource "aws_iam_role_policy" "eventbridge_codedeploy_policy" {
  count = var.enable_auto_deployment ? 1 : 0

  name = "${var.application_name}-eventbridge-codedeploy-policy"
  role = aws_iam_role.eventbridge_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Group for CodeDeploy
resource "aws_cloudwatch_log_group" "codedeploy_logs" {
  name              = "/aws/codedeploy/${var.application_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name    = "${var.application_name}-codedeploy-logs"
    Service = var.service_name
  })
}