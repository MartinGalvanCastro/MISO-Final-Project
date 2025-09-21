# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false  # Set to false for development

  tags = {
    Name        = "${var.project_name}-alb"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Target Group for Orders Service
resource "aws_lb_target_group" "orders_service" {
  name        = "${var.project_name}-orders-tg"
  port        = 8001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"  # Required for Fargate

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/v1/orders/health/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-orders-tg"
    Project     = var.project_name
    Environment = var.environment
    Service     = "orders-service"
  }
}

# Target Group for Orders Service (Green - for Blue-Green deployment)
resource "aws_lb_target_group" "orders_service_green" {
  name        = "${var.project_name}-orders-tg-green"
  port        = 8001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"  # Required for Fargate

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/v1/orders/health/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-orders-tg-green"
    Project     = var.project_name
    Environment = var.environment
    Service     = "orders-service"
    DeploymentColor = "green"
  }
}

# Target Group for Inventory Service
resource "aws_lb_target_group" "inventory_service" {
  name        = "${var.project_name}-inventory-tg"
  port        = 8002
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"  # Required for Fargate

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/v1/inventory/health/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-inventory-tg"
    Project     = var.project_name
    Environment = var.environment
    Service     = "inventory-service"
  }
}

# Target Group for Inventory Service (Green - for Blue-Green deployment)
resource "aws_lb_target_group" "inventory_service_green" {
  name        = "${var.project_name}-inventory-tg-green"
  port        = 8002
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"  # Required for Fargate

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/v1/inventory/health/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-inventory-tg-green"
    Project     = var.project_name
    Environment = var.environment
    Service     = "inventory-service"
    DeploymentColor = "green"
  }
}

# Target Group for Prometheus
resource "aws_lb_target_group" "prometheus" {
  name        = "${var.project_name}-prometheus-tg"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"  # Required for Fargate

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/prometheus/-/healthy"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-prometheus-tg"
    Project     = var.project_name
    Environment = var.environment
    Service     = "prometheus"
  }
}

# Target Group for Grafana
resource "aws_lb_target_group" "grafana" {
  name        = "${var.project_name}-grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"  # Required for Fargate

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-grafana-tg"
    Project     = var.project_name
    Environment = var.environment
    Service     = "grafana"
  }
}

# ALB Listener (HTTP only for cost savings)
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Default action - return 404 for unknown paths (blocks bots/scanners)
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Listener Rules for path-based routing
resource "aws_lb_listener_rule" "orders_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.orders_service.arn
        weight = 100
      }
      target_group {
        arn    = aws_lb_target_group.orders_service_green.arn
        weight = 0
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/v1/orders*"]
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Service     = "orders-service"
  }
}

resource "aws_lb_listener_rule" "inventory_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 200

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.inventory_service.arn
        weight = 100
      }
      target_group {
        arn    = aws_lb_target_group.inventory_service_green.arn
        weight = 0
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/v1/inventory*"]
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Service     = "inventory-service"
  }
}

resource "aws_lb_listener_rule" "prometheus" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus.arn
  }

  condition {
    path_pattern {
      values = ["/prometheus*"]
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Service     = "prometheus"
  }
}

resource "aws_lb_listener_rule" "grafana" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 400

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  condition {
    path_pattern {
      values = ["/grafana*"]
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Service     = "grafana"
  }
}