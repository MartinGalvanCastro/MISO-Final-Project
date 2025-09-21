# CodeDeploy Application for ECS Blue/Green Deployment
resource "aws_codedeploy_app" "ecs_app" {
  compute_platform = "ECS"
  name             = "${var.project_name}-ecs-app"

  tags = {
    Name        = "${var.project_name}-codedeploy-app"
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Role for CodeDeploy ECS Service
resource "aws_iam_role" "codedeploy_service_role" {
  name = "${var.project_name}-codedeploy-service-role"

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

  tags = {
    Name        = "${var.project_name}-codedeploy-service-role"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Attach CodeDeploy ECS Service Role Policy
resource "aws_iam_role_policy_attachment" "codedeploy_service_role_policy" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# CodeDeploy Deployment Group for Orders Service
resource "aws_codedeploy_deployment_group" "orders_service" {
  app_name               = aws_codedeploy_app.ecs_app.name
  deployment_group_name  = "${var.project_name}-orders-service-dg"
  service_role_arn       = aws_iam_role.codedeploy_service_role.arn
  deployment_config_name = "CodeDeployDefault.ECSLinear10PercentEvery1Minutes"

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                         = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.orders_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.alb_listener_arn]
      }

      target_group {
        name = var.orders_target_group_name
      }

      target_group {
        name = var.orders_target_group_name_green
      }
    }
  }



  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  alarm_configuration {
    enabled = true
    alarms  = [aws_cloudwatch_metric_alarm.orders_service_error_rate.alarm_name]
  }

  tags = {
    Name        = "${var.project_name}-orders-codedeploy-dg"
    Project     = var.project_name
    Environment = var.environment
    Service     = "orders-service"
  }
}

# CodeDeploy Deployment Group for Inventory Service
resource "aws_codedeploy_deployment_group" "inventory_service" {
  app_name               = aws_codedeploy_app.ecs_app.name
  deployment_group_name  = "${var.project_name}-inventory-service-dg"
  service_role_arn       = aws_iam_role.codedeploy_service_role.arn
  deployment_config_name = "CodeDeployDefault.ECSLinear10PercentEvery1Minutes"

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                         = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.inventory_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.alb_listener_arn]
      }

      target_group {
        name = var.inventory_target_group_name
      }

      target_group {
        name = var.inventory_target_group_name_green
      }
    }
  }



  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  alarm_configuration {
    enabled = true
    alarms  = [aws_cloudwatch_metric_alarm.inventory_service_error_rate.alarm_name]
  }

  tags = {
    Name        = "${var.project_name}-inventory-codedeploy-dg"
    Project     = var.project_name
    Environment = var.environment
    Service     = "inventory-service"
  }
}

# CloudWatch Alarm for Orders Service Error Rate (5% threshold)
resource "aws_cloudwatch_metric_alarm" "orders_service_error_rate" {
  alarm_name          = "${var.project_name}-orders-service-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  threshold           = "5"
  alarm_description   = "This metric monitors orders service 5xx error rate percentage"
  insufficient_data_actions = []
  treat_missing_data = "notBreaching"

  metric_query {
    id = "e1"
    expression = "m2/m1*100"
    label = "Error Rate Percentage"
    return_data = true
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "Sum"
      dimensions = {
        TargetGroup = var.orders_target_group_arn_suffix
      }
    }
  }

  metric_query {
    id = "m2"
    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "Sum"
      dimensions = {
        TargetGroup = var.orders_target_group_arn_suffix
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-orders-service-error-alarm"
    Project     = var.project_name
    Environment = var.environment
    Service     = "orders-service"
  }
}

# CloudWatch Alarm for Inventory Service Error Rate (5% threshold)
resource "aws_cloudwatch_metric_alarm" "inventory_service_error_rate" {
  alarm_name          = "${var.project_name}-inventory-service-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  threshold           = "5"
  alarm_description   = "This metric monitors inventory service 5xx error rate percentage"
  insufficient_data_actions = []
  treat_missing_data = "notBreaching"

  metric_query {
    id = "e1"
    expression = "m2/m1*100"
    label = "Error Rate Percentage"
    return_data = true
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "Sum"
      dimensions = {
        TargetGroup = var.inventory_target_group_arn_suffix
      }
    }
  }

  metric_query {
    id = "m2"
    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "Sum"
      dimensions = {
        TargetGroup = var.inventory_target_group_arn_suffix
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-inventory-service-error-alarm"
    Project     = var.project_name
    Environment = var.environment
    Service     = "inventory-service"
  }
}

