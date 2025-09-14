# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# EFS for Prometheus and Grafana persistent storage
resource "aws_efs_file_system" "monitoring_efs" {
  count = var.enable_persistent_storage ? 1 : 0

  creation_token = "${var.project_name}-monitoring-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "provisioned"
  provisioned_throughput_in_mibps = 10

  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-monitoring-efs"
    Purpose = "monitoring-storage"
  })
}

# EFS Mount Targets
resource "aws_efs_mount_target" "monitoring_efs_mt" {
  count = var.enable_persistent_storage ? length(var.private_subnet_ids) : 0

  file_system_id = aws_efs_file_system.monitoring_efs[0].id
  subnet_id      = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs[0].id]
}

# Security Group for EFS
resource "aws_security_group" "efs" {
  count = var.enable_persistent_storage ? 1 : 0

  name_prefix = "${var.project_name}-efs-"
  description = "Security group for EFS access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [aws_security_group.monitoring.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-efs-sg"
  })
}

# Security Group for Monitoring Services
resource "aws_security_group" "monitoring" {
  name_prefix = "${var.project_name}-monitoring-"
  description = "Security group for monitoring services"
  vpc_id      = var.vpc_id

  # Prometheus port
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Grafana port
  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Node Exporter port
  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    self        = true
  }

  # cAdvisor port
  ingress {
    description = "cAdvisor"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    self        = true
  }

  # Allow communication between services
  ingress {
    description = "Inter-service communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-monitoring-sg"
  })
}

# IAM Role for Monitoring Tasks
resource "aws_iam_role" "monitoring_task_role" {
  name = "${var.project_name}-monitoring-task-role"

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
    Name = "${var.project_name}-monitoring-task-role"
  })
}

# IAM Policy for CloudWatch metrics access (minimal)
resource "aws_iam_role_policy" "monitoring_cloudwatch_policy" {
  name = "${var.project_name}-monitoring-cloudwatch-policy"
  role = aws_iam_role.monitoring_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ecs:ListClusters",
          "ecs:ListServices",
          "ecs:DescribeServices",
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:DescribeTaskDefinition"
        ]
        Resource = "*"
      }
    ]
  })
}

# ECS Task Definition for Prometheus
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.project_name}-prometheus"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.prometheus_cpu
  memory                   = var.prometheus_memory
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn           = aws_iam_role.monitoring_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = var.prometheus_image
      essential = true

      portMappings = [
        {
          containerPort = 9090
          protocol      = "tcp"
        }
      ]

      entryPoint = ["sh", "-c"]
      command = [
        <<-EOT
          mkdir -p /etc/prometheus &&
          cat > /etc/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]
EOF
          prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --storage.tsdb.retention.time=${var.prometheus_retention_days}d --web.enable-lifecycle --web.enable-admin-api --web.route-prefix=/prometheus --web.external-url=http://${var.alb_dns_name}/prometheus
        EOT
      ]

      environment = [
        {
          name  = "PROMETHEUS_EXTERNAL_LABELS"
          value = "cluster=${var.project_name},environment=${var.environment}"
        }
      ]

      mountPoints = var.enable_persistent_storage ? [
        {
          sourceVolume  = "prometheus-data"
          containerPath = "/prometheus"
          readOnly      = false
        }
      ] : []

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.monitoring_logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "prometheus"
        }
      }

      healthCheck = {
        command = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:9090/-/healthy || exit 1"]
        interval = 30
        timeout  = 5
        retries  = 3
        startPeriod = 60
      }
    }
  ])

  dynamic "volume" {
    for_each = var.enable_persistent_storage ? [1] : []
    content {
      name = "prometheus-data"
      efs_volume_configuration {
        file_system_id = aws_efs_file_system.monitoring_efs[0].id
        root_directory = "/"
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = aws_efs_access_point.prometheus_data[0].id
          iam             = "ENABLED"
        }
      }
    }
  }


  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-prometheus-task"
    Service = "prometheus"
  })
}

# EFS Access Points
resource "aws_efs_access_point" "prometheus_data" {
  count = var.enable_persistent_storage ? 1 : 0

  file_system_id = aws_efs_file_system.monitoring_efs[0].id

  root_directory {
    path = "/prometheus"
    creation_info {
      owner_gid   = 65534
      owner_uid   = 65534
      permissions = 0755
    }
  }

  posix_user {
    gid = 65534
    uid = 65534
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-prometheus-data-ap"
  })
}


resource "aws_efs_access_point" "grafana_data" {
  count = var.enable_persistent_storage ? 1 : 0

  file_system_id = aws_efs_file_system.monitoring_efs[0].id

  root_directory {
    path = "/grafana"
    creation_info {
      owner_gid   = 472
      owner_uid   = 472
      permissions = 0755
    }
  }

  posix_user {
    gid = 472
    uid = 472
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-grafana-data-ap"
  })
}

# ECS Task Definition for Grafana
resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.project_name}-grafana"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.grafana_cpu
  memory                   = var.grafana_memory
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn           = aws_iam_role.monitoring_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "grafana"
      image     = var.grafana_image
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "GF_SECURITY_ADMIN_PASSWORD"
          value = var.grafana_admin_password
        },
        {
          name  = "GF_SERVER_ROOT_URL"
          value = "http://${var.alb_dns_name}/grafana"
        },
        {
          name  = "GF_SERVER_SERVE_FROM_SUB_PATH"
          value = "true"
        },
        {
          name  = "GF_INSTALL_PLUGINS"
          value = "grafana-clock-panel,grafana-simple-json-datasource"
        },
        {
          name  = "GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH"
          value = "/etc/grafana/provisioning/dashboards/overview.json"
        }
      ]

      mountPoints = var.enable_persistent_storage ? [
        {
          sourceVolume  = "grafana-data"
          containerPath = "/var/lib/grafana"
          readOnly      = false
        }
      ] : []

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.monitoring_logs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "grafana"
        }
      }

      healthCheck = {
        command = ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"]
        interval = 30
        timeout  = 5
        retries  = 3
        startPeriod = 60
      }
    }
  ])

  dynamic "volume" {
    for_each = var.enable_persistent_storage ? [1] : []
    content {
      name = "grafana-data"
      efs_volume_configuration {
        file_system_id = aws_efs_file_system.monitoring_efs[0].id
        root_directory = "/"
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = aws_efs_access_point.grafana_data[0].id
          iam             = "ENABLED"
        }
      }
    }
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-grafana-task"
    Service = "grafana"
  })
}

# CloudWatch Log Group (reduced retention for cost savings)
resource "aws_cloudwatch_log_group" "monitoring_logs" {
  name              = "/ecs/${var.project_name}-monitoring"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-monitoring-logs"
    Service = "monitoring"
  })
}

# ECS Service for Prometheus
resource "aws_ecs_service" "prometheus" {
  name            = "${var.project_name}-prometheus"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  platform_version = "1.4.0"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.monitoring.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prometheus.arn
    container_name   = "prometheus"
    container_port   = 9090
  }

  depends_on = [
    aws_lb_listener_rule.prometheus
  ]

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-prometheus-service"
    Service = "prometheus"
  })
}

# ECS Service for Grafana
resource "aws_ecs_service" "grafana" {
  name            = "${var.project_name}-grafana"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  platform_version = "1.4.0"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.monitoring.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener_rule.grafana
  ]

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-grafana-service"
    Service = "grafana"
  })
}

# Target Groups for ALB
resource "aws_lb_target_group" "prometheus" {
  name     = "${var.project_name}-prometheus-tg"
  port     = 9090
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/-/healthy"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-prometheus-tg"
  })
}

resource "aws_lb_target_group" "grafana" {
  name     = "${var.project_name}-grafana-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-grafana-tg"
  })
}

# ALB Listener Rules
resource "aws_lb_listener_rule" "prometheus" {
  listener_arn = var.alb_listener_arn
  priority     = var.prometheus_listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus.arn
  }

  condition {
    path_pattern {
      values = ["/prometheus*"]
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-prometheus-listener-rule"
  })
}

resource "aws_lb_listener_rule" "grafana" {
  listener_arn = var.alb_listener_arn
  priority     = var.grafana_listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  condition {
    path_pattern {
      values = ["/grafana*"]
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-grafana-listener-rule"
  })
}