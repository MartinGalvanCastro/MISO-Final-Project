# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  # Allow access from ECS security groups if provided, otherwise from VPC CIDR
  dynamic "ingress" {
    for_each = length(var.allowed_security_groups) > 0 ? [1] : []
    content {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = var.allowed_security_groups
    }
  }

  dynamic "ingress" {
    for_each = length(var.allowed_security_groups) == 0 ? [1] : []
    content {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-rds-sg"
  })
}

# RDS PostgreSQL Instance (cheapest configuration)
resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-postgres"

  # Engine configuration
  engine         = "postgres"
  engine_version = "15.7"
  instance_class = "db.t3.micro"  # Cheapest instance type

  # Storage configuration (cheapest)
  allocated_storage     = 20      # Minimum for PostgreSQL
  max_allocated_storage = 100     # Auto-scaling limit
  storage_type          = "gp2"   # Cheaper than gp3
  storage_encrypted     = false   # Cheaper without encryption

  # Database configuration
  db_name  = var.database_name
  username = var.database_username
  password = var.database_password
  port     = 5432

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Backup configuration (minimal for cost)
  backup_retention_period = 1      # Minimum retention
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Disable expensive features
  monitoring_interval             = 0      # No enhanced monitoring
  performance_insights_enabled    = false  # No performance insights
  enabled_cloudwatch_logs_exports = []     # No log exports

  # Availability and recovery
  multi_az               = false  # Single AZ for cost savings
  auto_minor_version_upgrade = true
  deletion_protection    = false  # Allow deletion for dev environment

  # Final snapshot
  skip_final_snapshot       = true  # Skip for dev environment
  delete_automated_backups  = true

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-postgres"
    Environment = var.environment
    Service     = "postgresql"
  })
}