# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Store password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.project_name}-db-password"
  description = "Database password for ${var.project_name}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

# Store DATABASE_URL in AWS Secrets Manager for application use
resource "aws_secretsmanager_secret" "database_url" {
  name        = "${var.project_name}-database-url"
  description = "Database connection URL for ${var.project_name}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = "postgresql+asyncpg://${var.db_username}:${urlencode(random_password.db_password.result)}@${aws_db_instance.main.endpoint}/${var.db_name}"
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-postgres"

  # Engine configuration
  engine         = "postgres"
  engine_version = "15.14"
  instance_class = var.db_instance_class

  # Storage configuration (free tier: 20GB)
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = true

  # Availability and maintenance
  multi_az               = false  # Single-AZ for cost savings
  availability_zone      = var.availability_zone
  backup_retention_period = 0     # Disable automated backups for cost savings
  maintenance_window     = "sun:04:00-sun:05:00"  # UTC

  # Performance and monitoring
  performance_insights_enabled = false  # Disable to save costs
  monitoring_interval         = 0       # Disable enhanced monitoring

  # Deletion protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  # Parameter group
  parameter_group_name = aws_db_parameter_group.main.name

  tags = {
    Name        = "${var.project_name}-postgres"
    Project     = var.project_name
    Environment = var.environment
  }
}

# DB Parameter Group for PostgreSQL optimizations
resource "aws_db_parameter_group" "main" {
  family = "postgres15"
  name   = "${var.project_name}-postgres-params"

  # Basic optimizations for small instance
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"  # Log queries taking more than 1 second
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}