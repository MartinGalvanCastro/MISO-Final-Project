# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ECS Cluster (created once per environment, shared by all services)
resource "aws_ecs_cluster" "cluster" {
  count = var.create_cluster ? 1 : 0
  name  = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_exec[0].name
      }
    }
  }

  tags = merge(var.common_tags, {
    Name        = var.cluster_name
    Description = "ECS Fargate cluster for ${var.cluster_name}"
  })
}

# CloudWatch Log Group for ECS Exec
resource "aws_cloudwatch_log_group" "ecs_exec" {
  count             = var.create_cluster ? 1 : 0
  name              = "/aws/ecs/cluster/${var.cluster_name}/exec"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-ecs-exec-logs"
  })
}

# CloudWatch Log Group for the service
resource "aws_cloudwatch_log_group" "service_logs" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name    = "${var.service_name}-logs"
    Service = var.service_name
  })
}

# ECS Task Execution Role
resource "aws_iam_role" "task_execution_role" {
  name = "${var.service_name}-task-execution-role"

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

  tags = merge(var.common_tags, {
    Name    = "${var.service_name}-task-execution-role"
    Service = var.service_name
  })
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for ECR access
resource "aws_iam_role_policy" "task_execution_ecr_policy" {
  name = "${var.service_name}-task-execution-ecr-policy"
  role = aws_iam_role.task_execution_role.id

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
}

# ECS Task Role (for the application itself)
resource "aws_iam_role" "task_role" {
  name = "${var.service_name}-task-role"

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

  tags = merge(var.common_tags, {
    Name    = "${var.service_name}-task-role"
    Service = var.service_name
  })
}

# Task role policy for application permissions
resource "aws_iam_role_policy" "task_role_policy" {
  count = length(var.task_role_policy_statements) > 0 ? 1 : 0
  name  = "${var.service_name}-task-policy"
  role  = aws_iam_role.task_role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = var.task_role_policy_statements
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "task" {
  family                   = var.service_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn           = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        for key, value in var.environment_variables : {
          name  = key
          value = value
        }
      ]

      secrets = [
        for key, valueFrom in var.secrets : {
          name      = key
          valueFrom = valueFrom
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.service_logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = var.health_check_command != null ? {
        command = var.health_check_command
        interval = var.health_check_interval
        timeout  = var.health_check_timeout
        retries  = var.health_check_retries
        startPeriod = var.health_check_start_period
      } : null
    }
  ])

  tags = merge(var.common_tags, {
    Name    = "${var.service_name}-task"
    Service = var.service_name
  })
}

# Security Group for ECS Service
resource "aws_security_group" "ecs_service" {
  name        = "${var.service_name}-ecs-sg"
  description = "Security group for ${var.service_name} ECS service"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from ALB"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    security_groups = var.alb_security_group_ids
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name    = "${var.service_name}-ecs-sg"
    Service = var.service_name
  })
}

# ECS Service
resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = var.create_cluster ? aws_ecs_cluster.cluster[0].id : var.existing_cluster_id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  platform_version = var.platform_version

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ecs_service.id]
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arns
    content {
      target_group_arn = load_balancer.value
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  deployment_configuration {
    maximum_percent         = var.deployment_maximum_percent
    minimum_healthy_percent = var.deployment_minimum_healthy_percent

    deployment_circuit_breaker {
      enable   = var.enable_deployment_circuit_breaker
      rollback = var.enable_deployment_rollback
    }
  }

  enable_execute_command = var.enable_execute_command

  depends_on = [
    aws_iam_role_policy_attachment.task_execution_role_policy
  ]

  tags = merge(var.common_tags, {
    Name    = "${var.service_name}-service"
    Service = var.service_name
  })

  lifecycle {
    ignore_changes = [task_definition]
  }
}

# Application Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.create_cluster ? aws_ecs_cluster.cluster[0].name : var.existing_cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = merge(var.common_tags, {
    Name    = "${var.service_name}-autoscaling-target"
    Service = var.service_name
  })
}

# CPU-based Auto Scaling Policy
resource "aws_appautoscaling_policy" "cpu_scaling_policy" {
  name               = "${var.service_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target_value
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

# Memory-based Auto Scaling Policy
resource "aws_appautoscaling_policy" "memory_scaling_policy" {
  name               = "${var.service_name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.memory_target_value
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.service_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ${var.service_name} CPU utilization"
  alarm_actions       = var.alarm_actions

  dimensions = {
    ServiceName = aws_ecs_service.service.name
    ClusterName = var.create_cluster ? aws_ecs_cluster.cluster[0].name : var.existing_cluster_name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.service_name}-high-cpu-alarm"
    Service = var.service_name
  })
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.service_name}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ${var.service_name} memory utilization"
  alarm_actions       = var.alarm_actions

  dimensions = {
    ServiceName = aws_ecs_service.service.name
    ClusterName = var.create_cluster ? aws_ecs_cluster.cluster[0].name : var.existing_cluster_name
  }

  tags = merge(var.common_tags, {
    Name    = "${var.service_name}-high-memory-alarm"
    Service = var.service_name
  })
}