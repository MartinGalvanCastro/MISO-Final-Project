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

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                         = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.orders_service_name
  }

  load_balancer_info {
    target_group_info {
      name = var.orders_target_group_name
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
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

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                         = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.inventory_service_name
  }

  load_balancer_info {
    target_group_info {
      name = var.inventory_target_group_name
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  tags = {
    Name        = "${var.project_name}-inventory-codedeploy-dg"
    Project     = var.project_name
    Environment = var.environment
    Service     = "inventory-service"
  }
}

# CodeDeploy Deployment Group for Prometheus
resource "aws_codedeploy_deployment_group" "prometheus" {
  app_name               = aws_codedeploy_app.ecs_app.name
  deployment_group_name  = "${var.project_name}-prometheus-dg"
  service_role_arn       = aws_iam_role.codedeploy_service_role.arn
  deployment_config_name = "CodeDeployDefault.ECSLinear10PercentEvery1Minutes"

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                         = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.prometheus_service_name
  }

  load_balancer_info {
    target_group_info {
      name = var.prometheus_target_group_name
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  tags = {
    Name        = "${var.project_name}-prometheus-codedeploy-dg"
    Project     = var.project_name
    Environment = var.environment
    Service     = "prometheus"
  }
}

# CodeDeploy Deployment Group for Grafana
resource "aws_codedeploy_deployment_group" "grafana" {
  app_name               = aws_codedeploy_app.ecs_app.name
  deployment_group_name  = "${var.project_name}-grafana-dg"
  service_role_arn       = aws_iam_role.codedeploy_service_role.arn
  deployment_config_name = "CodeDeployDefault.ECSLinear10PercentEvery1Minutes"

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                         = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.grafana_service_name
  }

  load_balancer_info {
    target_group_info {
      name = var.grafana_target_group_name
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  tags = {
    Name        = "${var.project_name}-grafana-codedeploy-dg"
    Project     = var.project_name
    Environment = var.environment
    Service     = "grafana"
  }
}