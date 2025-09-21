# Task Definition for Orders Service
resource "aws_ecs_task_definition" "orders_service" {
  family                   = "${var.project_name}-orders-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # 0.25 vCPU
  memory                   = "512"  # 512 MB

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "orders-service"
      image = "${var.ecr_repositories.orders_service}:latest"

      essential = true

      portMappings = [
        {
          containerPort = 8001
          protocol      = "tcp"
          name          = "orders-service"
        }
      ]

      environment = [
        {
          name  = "APP_NAME"
          value = "orders-service"
        },
        {
          name  = "PORT"
          value = "8001"
        },
        {
          name  = "DEBUG"
          value = "false"
        },
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "LOG_LEVEL"
          value = "INFO"
        },
        {
          name  = "INVENTORY_SERVICE_URL"
          value = "http://inventory-service.${var.service_discovery_namespace_name}:8002"
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "SQS_QUEUE_URL"
          value = var.orders_queue_url
        },
        {
          name  = "SQS_QUEUE_NAME"
          value = var.orders_queue_name
        },
        {
          name  = "HEALTH_CHECK_PATH"
          value = "/health/"
        },
        {
          name  = "DATABASE_URL"
          value = var.database_url_connection_string
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.orders_service.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8001/health/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-orders-service-task"
    Project     = var.project_name
    Environment = var.environment
    Service     = "orders-service"
  }
}

# Service Connect Service for Orders
resource "aws_service_discovery_service" "orders_service" {
  name = "orders-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 60
      type = "A"
    }
  }

  tags = {
    Name        = "${var.project_name}-orders-service-discovery"
    Project     = var.project_name
    Environment = var.environment
    Service     = "orders-service"
  }
}

# ECS Service for Orders
resource "aws_ecs_service" "orders_service" {
  name            = "${var.project_name}-orders-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.orders_service.arn
  desired_count   = var.orders_service_min_capacity
  launch_type     = "FARGATE"

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.orders_target_group_arn
    container_name   = "orders-service"
    container_port   = 8001
  }

  service_registries {
    registry_arn = aws_service_discovery_service.orders_service.arn
  }

  enable_execute_command = false  # Disable for cost savings

  depends_on = [var.alb_listener_arn]

  tags = {
    Name        = "${var.project_name}-orders-service"
    Project     = var.project_name
    Environment = var.environment
    Service     = "orders-service"
  }
}

# Auto Scaling for Orders Service
resource "aws_appautoscaling_target" "orders_service" {
  max_capacity       = var.orders_service_max_capacity
  min_capacity       = var.orders_service_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.orders_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Service     = "orders-service"
  }
}

resource "aws_appautoscaling_policy" "orders_service_cpu" {
  name               = "${var.project_name}-orders-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.orders_service.resource_id
  scalable_dimension = aws_appautoscaling_target.orders_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.orders_service.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Task Definition for Inventory Service
resource "aws_ecs_task_definition" "inventory_service" {
  family                   = "${var.project_name}-inventory-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # 0.25 vCPU
  memory                   = "512"  # 512 MB

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "inventory-service"
      image = "${var.ecr_repositories.inventory_service}:latest"

      essential = true

      portMappings = [
        {
          containerPort = 8002
          protocol      = "tcp"
          name          = "inventory-service"
        }
      ]

      environment = [
        {
          name  = "APP_NAME"
          value = "inventory-service"
        },
        {
          name  = "PORT"
          value = "8002"
        },
        {
          name  = "DEBUG"
          value = "false"
        },
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "LOG_LEVEL"
          value = "INFO"
        },
        {
          name  = "HEALTH_CHECK_PATH"
          value = "/health/"
        },
        {
          name  = "DEFAULT_STOCK_QUANTITY"
          value = "100"
        },
        {
          name  = "LOW_STOCK_THRESHOLD"
          value = "10"
        },
        {
          name  = "RESERVATION_TIMEOUT_MINUTES"
          value = "15"
        },
        {
          name  = "DATABASE_URL"
          value = var.database_url_connection_string
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.inventory_service.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8002/health/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-inventory-service-task"
    Project     = var.project_name
    Environment = var.environment
    Service     = "inventory-service"
  }
}

# Service Connect Service for Inventory
resource "aws_service_discovery_service" "inventory_service" {
  name = "inventory-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 60
      type = "A"
    }
  }

  tags = {
    Name        = "${var.project_name}-inventory-service-discovery"
    Project     = var.project_name
    Environment = var.environment
    Service     = "inventory-service"
  }
}

# ECS Service for Inventory
resource "aws_ecs_service" "inventory_service" {
  name            = "${var.project_name}-inventory-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.inventory_service.arn
  desired_count   = var.inventory_service_desired_count
  launch_type     = "FARGATE"

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.inventory_target_group_arn
    container_name   = "inventory-service"
    container_port   = 8002
  }

  service_registries {
    registry_arn = aws_service_discovery_service.inventory_service.arn
  }

  enable_execute_command = false  # Disable for cost savings

  depends_on = [var.alb_listener_arn]

  tags = {
    Name        = "${var.project_name}-inventory-service"
    Project     = var.project_name
    Environment = var.environment
    Service     = "inventory-service"
  }
}

