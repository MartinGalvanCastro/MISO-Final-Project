# Task Definition for Prometheus
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.project_name}-prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # 0.25 vCPU
  memory                   = "512"  # 512 MB

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "prometheus"
      image = "${var.ecr_repositories.prometheus}:latest"

      essential = true

      portMappings = [
        {
          containerPort = 9090
          protocol      = "tcp"
          name          = "prometheus"
        }
      ]


      environment = [
        {
          name  = "ORDERS_SERVICE_URL"
          value = "${var.alb_dns_name}/api/v1/orders"
        },
        {
          name  = "INVENTORY_SERVICE_URL"
          value = "${var.alb_dns_name}/api/v1/inventory"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.prometheus.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:9090/prometheus/-/healthy || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-prometheus-task"
    Project     = var.project_name
    Environment = var.environment
    Service     = "prometheus"
  }
}


# ECS Service for Prometheus
resource "aws_ecs_service" "prometheus" {
  name            = "${var.project_name}-prometheus"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.prometheus_target_group_arn
    container_name   = "prometheus"
    container_port   = 9090
  }


  enable_execute_command = false  # Disable for cost savings

  depends_on = [var.alb_listener_arn]

  tags = {
    Name        = "${var.project_name}-prometheus"
    Project     = var.project_name
    Environment = var.environment
    Service     = "prometheus"
  }
}

# Task Definition for Grafana
resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.project_name}-grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # 0.25 vCPU
  memory                   = "512"  # 512 MB

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "grafana"
      image = "${var.ecr_repositories.grafana}:latest"

      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
          name          = "grafana"
        }
      ]

      environment = [
        {
          name  = "GF_SERVER_HTTP_PORT"
          value = "3000"
        },
        {
          name  = "GF_SERVER_ROOT_URL"
          value = "http://localhost:3000/grafana"
        },
        {
          name  = "GF_SERVER_SERVE_FROM_SUB_PATH"
          value = "true"
        },
        {
          name  = "PROMETHEUS_URL"
          value = "http://${var.alb_dns_name}/prometheus"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.grafana.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-grafana-task"
    Project     = var.project_name
    Environment = var.environment
    Service     = "grafana"
  }
}


# ECS Service for Grafana
resource "aws_ecs_service" "grafana" {
  name            = "${var.project_name}-grafana"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.grafana_target_group_arn
    container_name   = "grafana"
    container_port   = 3000
  }


  enable_execute_command = false  # Disable for cost savings

  depends_on = [var.alb_listener_arn]

  tags = {
    Name        = "${var.project_name}-grafana"
    Project     = var.project_name
    Environment = var.environment
    Service     = "grafana"
  }
}