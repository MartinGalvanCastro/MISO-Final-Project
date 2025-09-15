terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ECR Repository for Orders Service
module "orders_service_ecr" {
  source = "./modules/ecr"

  repository_name = var.orders_service_repo_name
  service_name    = "orders"
  description     = "Container repository for orders microservice"

  # Lifecycle policy configuration
  keep_versioned_images = var.ecr_keep_versioned_images
  keep_latest_images    = var.ecr_keep_latest_images
  untagged_expiry_days  = var.ecr_untagged_expiry_days

  # Configuration
  image_tag_mutability = var.ecr_image_tag_mutability
  scan_on_push        = var.ecr_scan_on_push

  common_tags = merge(var.common_tags, {
    Service = "orders"
  })
}

# ECR Repository for Inventory Service
module "inventory_service_ecr" {
  source = "./modules/ecr"

  repository_name = var.inventory_service_repo_name
  service_name    = "inventory"
  description     = "Container repository for inventory microservice"

  # Lifecycle policy configuration
  keep_versioned_images = var.ecr_keep_versioned_images
  keep_latest_images    = var.ecr_keep_latest_images
  untagged_expiry_days  = var.ecr_untagged_expiry_days

  # Configuration
  image_tag_mutability = var.ecr_image_tag_mutability
  scan_on_push        = var.ecr_scan_on_push

  common_tags = merge(var.common_tags, {
    Service = "inventory"
  })
}

# SQS Queue for Orders Service Events
module "orders_service_sqs" {
  source = "./modules/sqs"

  queue_name   = var.orders_queue_name
  service_name = "orders"
  description  = "Queue for publishing orders service events"

  # Queue Configuration
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  message_retention_seconds  = var.sqs_message_retention_seconds
  receive_wait_time_seconds  = var.sqs_receive_wait_time_seconds
  max_message_size          = var.sqs_max_message_size

  # No Dead Letter Queue needed for event publishing
  enable_dead_letter_queue = false

  # Monitoring
  enable_cloudwatch_alarms    = var.sqs_enable_cloudwatch_alarms
  queue_depth_alarm_threshold = var.sqs_queue_depth_alarm_threshold

  # Encryption (optional)
  kms_master_key_id = var.sqs_kms_master_key_id

  common_tags = merge(var.common_tags, {
    Service = "orders"
    Purpose = "event-publishing"
  })
}

# CodeBuild Project for Orders Service
module "orders_service_codebuild" {
  source = "./modules/codebuild"

  project_name = "${var.project_name}-orders-service-build"
  service_name = "orders"
  description  = "CodeBuild project for orders service CI/CD pipeline"

  # ECR Integration
  ecr_repository_arn = module.orders_service_ecr.repository_arn
  ecr_repository_url = module.orders_service_ecr.repository_url

  # Build Configuration
  compute_type    = var.codebuild_compute_type
  build_image     = var.codebuild_image
  privileged_mode = true # Required for Docker builds

  # Source Configuration (GitHub direct access)
  source_type     = "GITHUB"
  source_location = var.orders_service_source_location

  # Disable webhook since we use GitHub Actions
  enable_webhook  = false

  # Custom buildspec with manual git clone
  buildspec_file = <<EOF
version: 0.2

phases:
  pre_build:
    commands:
      - cd services/orders-service
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPOSITORY_URI=$ECR_REPOSITORY_URI
      - COMMIT_HASH=$(git rev-parse --short HEAD)
      - IMAGE_TAG=$${IMAGE_TAG:-latest}
      - BUILD_NUMBER=$${CODEBUILD_BUILD_NUMBER:-1}
      - VERSION_TAG=$${VERSION_TAG:-v1.0.$BUILD_NUMBER}
      - echo Build started on `date`
      - echo Building the Docker image for orders-service...
      - echo "Repository URI:" $REPOSITORY_URI
      - echo "Image tags:" $IMAGE_TAG, $VERSION_TAG, $COMMIT_HASH, build-$BUILD_NUMBER

  build:
    commands:
      - echo Building Docker image...
      - cd /tmp/source/services/orders-service
      - docker build -t $REPOSITORY_URI:latest .
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$VERSION_TAG
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$COMMIT_HASH
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:build-$BUILD_NUMBER
      - echo Docker image built successfully

  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker images to ECR...
      - docker push $REPOSITORY_URI:latest
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - docker push $REPOSITORY_URI:$VERSION_TAG
      - docker push $REPOSITORY_URI:$COMMIT_HASH
      - docker push $REPOSITORY_URI:build-$BUILD_NUMBER
      - echo Docker images pushed successfully
      - echo "✅ Image URI with latest tag:" $REPOSITORY_URI:latest
      - echo "✅ Image URI with version tag:" $REPOSITORY_URI:$VERSION_TAG
      - echo "✅ Image URI with commit hash:" $REPOSITORY_URI:$COMMIT_HASH
      - echo "✅ Image URI with build number:" $REPOSITORY_URI:build-$BUILD_NUMBER

artifacts:
  files:
    - "**/*"
  name: orders-service-build-artifacts
EOF

  # Environment Variables
  environment_variables = merge(var.codebuild_environment_variables, {
    SERVICE_NAME = "orders-service"
    VERSION_TAG  = var.orders_service_version_tag
  })

  # Logging
  log_retention_days = var.codebuild_log_retention_days

  # Monitoring
  enable_build_failure_alarm = var.codebuild_enable_alarms

  # Webhook Configuration (disabled - using GitHub Actions)
  # enable_webhook = false

  common_tags = merge(var.common_tags, {
    Service = "orders"
    Purpose = "ci-cd"
  })
}

# CodeBuild Project for Inventory Service
module "inventory_service_codebuild" {
  source = "./modules/codebuild"

  project_name = "${var.project_name}-inventory-service-build"
  service_name = "inventory"
  description  = "CodeBuild project for inventory service CI/CD pipeline"

  # ECR Integration
  ecr_repository_arn = module.inventory_service_ecr.repository_arn
  ecr_repository_url = module.inventory_service_ecr.repository_url

  # Build Configuration
  compute_type    = var.codebuild_compute_type
  build_image     = var.codebuild_image
  privileged_mode = true # Required for Docker builds

  # Source Configuration (GitHub direct access)
  source_type     = "GITHUB"
  source_location = var.inventory_service_source_location

  # Disable webhook since we use GitHub Actions
  enable_webhook  = false

  # Custom buildspec with manual git clone
  buildspec_file = <<EOF
version: 0.2

phases:
  pre_build:
    commands:
      - cd services/inventory-service
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPOSITORY_URI=$ECR_REPOSITORY_URI
      - COMMIT_HASH=$(git rev-parse --short HEAD)
      - IMAGE_TAG=$${IMAGE_TAG:-latest}
      - BUILD_NUMBER=$${CODEBUILD_BUILD_NUMBER:-1}
      - VERSION_TAG=$${VERSION_TAG:-v1.0.$BUILD_NUMBER}
      - echo Build started on `date`
      - echo Building the Docker image for inventory-service...
      - echo "Repository URI:" $REPOSITORY_URI
      - echo "Image tags:" $IMAGE_TAG, $VERSION_TAG, $COMMIT_HASH, build-$BUILD_NUMBER

  build:
    commands:
      - echo Building Docker image...
      - cd /tmp/source/services/inventory-service
      - docker build -t $REPOSITORY_URI:latest .
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$VERSION_TAG
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$COMMIT_HASH
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:build-$BUILD_NUMBER
      - echo Docker image built successfully

  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker images to ECR...
      - docker push $REPOSITORY_URI:latest
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - docker push $REPOSITORY_URI:$VERSION_TAG
      - docker push $REPOSITORY_URI:$COMMIT_HASH
      - docker push $REPOSITORY_URI:build-$BUILD_NUMBER
      - echo Docker images pushed successfully
      - echo "✅ Image URI with latest tag:" $REPOSITORY_URI:latest
      - echo "✅ Image URI with version tag:" $REPOSITORY_URI:$VERSION_TAG
      - echo "✅ Image URI with commit hash:" $REPOSITORY_URI:$COMMIT_HASH
      - echo "✅ Image URI with build number:" $REPOSITORY_URI:build-$BUILD_NUMBER

artifacts:
  files:
    - "**/*"
  name: inventory-service-build-artifacts
EOF

  # Environment Variables
  environment_variables = merge(var.codebuild_environment_variables, {
    SERVICE_NAME = "inventory-service"
    VERSION_TAG  = var.inventory_service_version_tag
  })

  # Logging
  log_retention_days = var.codebuild_log_retention_days

  # Monitoring
  enable_build_failure_alarm = var.codebuild_enable_alarms

  # Webhook Configuration (disabled - using GitHub Actions)
  # enable_webhook = false

  common_tags = merge(var.common_tags, {
    Service = "inventory"
    Purpose = "ci-cd"
  })
}

# VPC for ECS Services
module "vpc" {
  source = "./modules/vpc"

  name = "${var.project_name}-vpc"
  cidr_block = var.vpc_cidr_block

  # Subnet Configuration
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count

  # Network Features
  enable_dns_hostnames = true
  enable_dns_support   = true
  create_nat_gateways  = var.create_nat_gateways
  create_s3_endpoint   = var.create_s3_endpoint

  common_tags = var.common_tags
}

# CodeStar Connection for GitHub
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_name}-github-connection"
  provider_type = "GitHub"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-github-connection"
    Description = "CodeStar connection to GitHub for CodePipeline"
    Purpose     = "CI/CD"
  })
}

# S3 Bucket for CodePipeline Artifacts
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "${var.project_name}-codepipeline-artifacts-${random_id.bucket_suffix.hex}"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-codepipeline-artifacts"
    Description = "S3 bucket for CodePipeline artifacts"
    Purpose     = "CI/CD"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# RDS PostgreSQL Database (cheapest configuration)
module "rds" {
  source = "./modules/rds"

  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Allow access from VPC CIDR for now (will be restricted later)
  allowed_security_groups = []

  # Database configuration
  database_name     = "medisupply"
  database_username = "postgres"
  database_password = var.database_password

  common_tags = var.common_tags
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"

  name = "${var.project_name}-alb"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  # ALB Configuration
  internal = false
  enable_deletion_protection = var.alb_enable_deletion_protection
  idle_timeout = var.alb_idle_timeout

  # Access Logs (optional)
  enable_access_logs = var.alb_enable_access_logs
  access_logs_bucket = var.alb_access_logs_bucket
  access_logs_prefix = "alb"

  # HTTPS Configuration (optional)
  certificate_arn = var.alb_certificate_arn

  # Target Groups for Services
  target_groups = [
    {
      name     = "${var.project_name}-orders-tg"
      port     = 8001
      protocol = "HTTP"
      path_pattern = "/api/orders*"
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 5
        interval            = 30
        path                = "/api/orders/health"
        matcher             = "200"
        port                = "traffic-port"
        protocol            = "HTTP"
      }
    },
    {
      name     = "${var.project_name}-inventory-tg"
      port     = 8002
      protocol = "HTTP"
      path_pattern = "/api/inventory*"
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 5
        interval            = 30
        path                = "/api/inventory/health"
        matcher             = "200"
        port                = "traffic-port"
        protocol            = "HTTP"
      }
    }
  ]

  common_tags = var.common_tags
}

# Blue/Green Target Groups for CodeDeploy
# Orders Service Blue Target Group
resource "aws_lb_target_group" "orders_blue" {
  name        = "${var.project_name}-orders-blue-tg"
  port        = 8001
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/orders/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-orders-blue-tg"
    Service = "orders"
    Type    = "blue"
  })
}

# Orders Service Green Target Group
resource "aws_lb_target_group" "orders_green" {
  name        = "${var.project_name}-orders-green-tg"
  port        = 8001
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/orders/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-orders-green-tg"
    Service = "orders"
    Type    = "green"
  })
}

# Inventory Service Blue Target Group
resource "aws_lb_target_group" "inventory_blue" {
  name        = "${var.project_name}-inventory-blue-tg"
  port        = 8002
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/inventory/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-inventory-blue-tg"
    Service = "inventory"
    Type    = "blue"
  })
}

# Inventory Service Green Target Group
resource "aws_lb_target_group" "inventory_green" {
  name        = "${var.project_name}-inventory-green-tg"
  port        = 8002
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/inventory/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-inventory-green-tg"
    Service = "inventory"
    Type    = "green"
  })
}

# ALB Listener Rules for Blue Target Groups
resource "aws_lb_listener_rule" "orders_blue" {
  listener_arn = module.alb.http_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.orders_blue.arn
  }

  condition {
    path_pattern {
      values = ["/api/orders*"]
    }
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-orders-blue-rule"
    Service = "orders"
    Type    = "blue"
  })
}

resource "aws_lb_listener_rule" "inventory_blue" {
  listener_arn = module.alb.http_listener_arn
  priority     = 210

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.inventory_blue.arn
  }

  condition {
    path_pattern {
      values = ["/api/inventory*"]
    }
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-inventory-blue-rule"
    Service = "inventory"
    Type    = "blue"
  })
}

# ECS Fargate Deployment - Orders Service
module "orders_service_ecs" {
  source = "./modules/ecs-fargate"

  # Service Configuration
  service_name = "${var.project_name}-orders-service"
  cluster_name = "${var.project_name}-cluster"

  # Container Configuration
  container_image = "${module.orders_service_ecr.repository_url}:latest"
  container_port  = 8001
  cpu             = var.ecs_orders_cpu
  memory          = var.ecs_orders_memory

  # Environment Variables
  environment_variables = {
    APP_NAME    = "orders-service"
    PORT        = "8001"
    DEBUG       = "false"
    ENVIRONMENT = var.environment

    # Database Configuration
    DATABASE_URL = module.rds.database_url

    # External Services
    INVENTORY_SERVICE_URL = "http://${var.project_name}-inventory-service:8002"

    # AWS Configuration
    AWS_REGION = var.aws_region
    SQS_QUEUE_URL = module.orders_service_sqs.queue_url
  }

  # Secrets from Parameter Store/Secrets Manager
  secrets = var.ecs_orders_secrets

  # Networking
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  alb_security_group_ids = [module.alb.security_group_id]

  # Load Balancer Integration (Blue Target Group for Blue-Green Deployment)
  target_group_arns = [aws_lb_target_group.orders_blue.arn]

  # Auto Scaling Configuration (3-6 replicas as requested)
  desired_count = 3
  min_capacity  = 3
  max_capacity  = 6

  cpu_target_value    = var.ecs_cpu_target_value
  memory_target_value = var.ecs_memory_target_value

  # Health Check
  health_check_command = ["CMD-SHELL", "curl -f http://localhost:8001/api/orders/health || exit 1"]
  health_check_interval = 30
  health_check_timeout  = 5
  health_check_retries  = 3
  health_check_start_period = 60

  # IAM Permissions
  task_role_policy_statements = [
    {
      Effect = "Allow"
      Action = [
        "sqs:SendMessage",
        "sqs:GetQueueUrl"
      ]
      Resource = [module.orders_service_sqs.queue_arn]
    }
  ]

  # Logging
  log_retention_days = var.ecs_log_retention_days

  # Monitoring
  enable_cloudwatch_alarms = var.ecs_enable_cloudwatch_alarms

  # Blue-Green Deployment Configuration
  enable_blue_green_deployment = var.enable_blue_green_deployment

  common_tags = merge(var.common_tags, {
    Service = "orders"
  })
}

# ECS Fargate Deployment - Inventory Service
module "inventory_service_ecs" {
  source = "./modules/ecs-fargate"

  # Service Configuration
  service_name = "${var.project_name}-inventory-service"
  cluster_name = "${var.project_name}-cluster"
  create_cluster = false
  existing_cluster_id = module.orders_service_ecs.cluster_id
  existing_cluster_name = module.orders_service_ecs.cluster_name

  # Container Configuration
  container_image = "${module.inventory_service_ecr.repository_url}:latest"
  container_port  = 8002
  cpu             = var.ecs_inventory_cpu
  memory          = var.ecs_inventory_memory

  # Environment Variables
  environment_variables = {
    APP_NAME    = "inventory-service"
    PORT        = "8002"
    DEBUG       = "false"
    ENVIRONMENT = var.environment

    # Database Configuration
    DATABASE_URL = module.rds.database_url

    # AWS Configuration
    AWS_REGION = var.aws_region
  }

  # Secrets from Parameter Store/Secrets Manager
  secrets = var.ecs_inventory_secrets

  # Networking
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  alb_security_group_ids = [module.alb.security_group_id]

  # Load Balancer Integration (Blue Target Group for Blue-Green Deployment)
  target_group_arns = [aws_lb_target_group.inventory_blue.arn]

  # Auto Scaling Configuration (3-6 replicas as requested)
  desired_count = 3
  min_capacity  = 3
  max_capacity  = 6

  cpu_target_value    = var.ecs_cpu_target_value
  memory_target_value = var.ecs_memory_target_value

  # Health Check
  health_check_command = ["CMD-SHELL", "curl -f http://localhost:8002/api/inventory/health || exit 1"]
  health_check_interval = 30
  health_check_timeout  = 5
  health_check_retries  = 3
  health_check_start_period = 60

  # Logging
  log_retention_days = var.ecs_log_retention_days

  # Monitoring
  enable_cloudwatch_alarms = var.ecs_enable_cloudwatch_alarms

  # Blue-Green Deployment Configuration
  enable_blue_green_deployment = var.enable_blue_green_deployment

  common_tags = merge(var.common_tags, {
    Service = "inventory"
  })
}

# CodeDeploy for Orders Service
module "orders_service_codedeploy" {
  count = var.enable_blue_green_deployment ? 1 : 0
  source = "./modules/codedeploy"

  # Application Configuration
  application_name        = "${var.project_name}-orders-service-codedeploy"
  service_name           = "orders"
  deployment_group_name  = "orders-deployment-group"

  # ECS Configuration
  ecs_cluster_name       = "${var.project_name}-cluster"
  ecs_service_name       = "${var.project_name}-orders-service"
  ecs_task_role_arn      = module.orders_service_ecs.task_role_arn
  ecs_execution_role_arn = module.orders_service_ecs.task_execution_role_arn

  # Load Balancer Configuration
  target_group_name = "${var.project_name}-orders-tg"  # deprecated
  blue_target_group_name  = aws_lb_target_group.orders_blue.name
  green_target_group_name = aws_lb_target_group.orders_green.name
  listener_arn = module.alb.http_listener_arn

  # Blue-Green Deployment Configuration
  termination_wait_time_minutes = var.codedeploy_termination_wait_time_minutes

  # Auto Rollback Configuration
  auto_rollback_enabled = var.codedeploy_auto_rollback_enabled

  # ECR Integration for Auto-deployment (disabled - using CodePipeline instead)
  enable_auto_deployment = false
  ecr_repository_name    = var.orders_service_repo_name
  ecr_trigger_tags       = var.codedeploy_ecr_trigger_tags

  # Logging Configuration
  log_retention_days = var.codedeploy_log_retention_days

  common_tags = merge(var.common_tags, {
    Service = "orders"
    Purpose = "deployment"
  })

  depends_on = [
    module.orders_service_ecs,
    module.alb
  ]
}

# CodeDeploy for Inventory Service
module "inventory_service_codedeploy" {
  count = var.enable_blue_green_deployment ? 1 : 0
  source = "./modules/codedeploy"

  # Application Configuration
  application_name        = "${var.project_name}-inventory-service-codedeploy"
  service_name           = "inventory"
  deployment_group_name  = "inventory-deployment-group"

  # ECS Configuration
  ecs_cluster_name       = "${var.project_name}-cluster"
  ecs_service_name       = "${var.project_name}-inventory-service"
  ecs_task_role_arn      = module.inventory_service_ecs.task_role_arn
  ecs_execution_role_arn = module.inventory_service_ecs.task_execution_role_arn

  # Load Balancer Configuration
  target_group_name = "${var.project_name}-inventory-tg"  # deprecated
  blue_target_group_name  = aws_lb_target_group.inventory_blue.name
  green_target_group_name = aws_lb_target_group.inventory_green.name
  listener_arn = module.alb.http_listener_arn

  # Blue-Green Deployment Configuration
  termination_wait_time_minutes = var.codedeploy_termination_wait_time_minutes

  # Auto Rollback Configuration
  auto_rollback_enabled = var.codedeploy_auto_rollback_enabled

  # ECR Integration for Auto-deployment (disabled - using CodePipeline instead)
  enable_auto_deployment = false
  ecr_repository_name    = var.inventory_service_repo_name
  ecr_trigger_tags       = var.codedeploy_ecr_trigger_tags

  # Logging Configuration
  log_retention_days = var.codedeploy_log_retention_days

  common_tags = merge(var.common_tags, {
    Service = "inventory"
    Purpose = "deployment"
  })

  depends_on = [
    module.inventory_service_ecs,
    module.alb
  ]
}

# CodePipeline for Orders Service
module "orders_service_codepipeline" {
  count = var.enable_blue_green_deployment ? 1 : 0
  source = "./modules/codepipeline"

  # Pipeline Configuration
  pipeline_name = "${var.project_name}-orders-pipeline"
  service_name  = "orders"

  # Source Configuration
  github_owner         = var.github_owner
  github_repo          = var.github_repo
  github_branch        = var.github_branch
  github_connection_arn = aws_codestarconnections_connection.github.arn

  # Build Configuration
  codebuild_project_name = module.orders_service_codebuild.project_name

  # Deploy Configuration
  codedeploy_application_name  = var.enable_blue_green_deployment ? module.orders_service_codedeploy[0].application_name : ""
  codedeploy_deployment_group  = "orders-deployment-group"

  # Artifacts Configuration
  artifacts_bucket_name = aws_s3_bucket.codepipeline_artifacts.bucket
  artifacts_bucket_arn  = aws_s3_bucket.codepipeline_artifacts.arn

  # Pipeline Configuration
  enable_manual_approval = var.codepipeline_enable_manual_approval
  environment           = var.environment

  # Logging Configuration
  log_retention_days = var.codepipeline_log_retention_days

  common_tags = merge(var.common_tags, {
    Service = "orders"
    Purpose = "ci-cd"
  })

  depends_on = [
    module.orders_service_codebuild,
    module.orders_service_codedeploy
  ]
}

# CodePipeline for Inventory Service
module "inventory_service_codepipeline" {
  count = var.enable_blue_green_deployment ? 1 : 0
  source = "./modules/codepipeline"

  # Pipeline Configuration
  pipeline_name = "${var.project_name}-inventory-pipeline"
  service_name  = "inventory"

  # Source Configuration
  github_owner         = var.github_owner
  github_repo          = var.github_repo
  github_branch        = var.github_branch
  github_connection_arn = aws_codestarconnections_connection.github.arn

  # Build Configuration
  codebuild_project_name = module.inventory_service_codebuild.project_name

  # Deploy Configuration
  codedeploy_application_name  = var.enable_blue_green_deployment ? module.inventory_service_codedeploy[0].application_name : ""
  codedeploy_deployment_group  = "inventory-deployment-group"

  # Artifacts Configuration
  artifacts_bucket_name = aws_s3_bucket.codepipeline_artifacts.bucket
  artifacts_bucket_arn  = aws_s3_bucket.codepipeline_artifacts.arn

  # Pipeline Configuration
  enable_manual_approval = var.codepipeline_enable_manual_approval
  environment           = var.environment

  # Logging Configuration
  log_retention_days = var.codepipeline_log_retention_days

  common_tags = merge(var.common_tags, {
    Service = "inventory"
    Purpose = "ci-cd"
  })

  depends_on = [
    module.inventory_service_codebuild,
    module.inventory_service_codedeploy
  ]
}

# SRE Monitoring Stack
module "monitoring" {
  count = var.enable_sre_monitoring ? 1 : 0
  source = "./modules/monitoring"

  # Project Configuration
  project_name = var.project_name
  environment  = var.environment

  # Network Configuration
  vpc_id                   = module.vpc.vpc_id
  private_subnet_ids       = module.vpc.private_subnet_ids
  alb_security_group_id    = module.alb.security_group_id
  alb_listener_arn         = module.alb.http_listener_arn
  alb_dns_name            = module.alb.dns_name

  # ECS Configuration
  ecs_cluster_id           = module.orders_service_ecs.cluster_id
  ecs_cluster_name         = module.orders_service_ecs.cluster_name
  ecs_execution_role_arn   = module.orders_service_ecs.task_execution_role_arn

  # Monitoring Configuration
  prometheus_retention_days = var.prometheus_retention_days
  grafana_admin_password   = var.grafana_admin_password
  enable_persistent_storage = var.enable_persistent_monitoring_storage

  # Cost Optimization
  log_retention_days       = var.monitoring_log_retention_days
  enable_cost_optimization = var.enable_cost_optimized_logging

  # Load Testing Settings
  enable_load_test_metrics = true
  load_test_dashboard_enabled = true

  # SRE Thresholds
  sre_thresholds = {
    high_cpu_percent         = 80
    high_memory_percent      = 85
    high_latency_ms         = 1000
    low_availability_percent = 99
    high_error_rate_percent  = 5
  }

  # Alerting (optional)
  enable_alerting = true
  # alert_webhook_url = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"

  common_tags = merge(var.common_tags, {
    Purpose = "sre-monitoring"
  })

  depends_on = [
    module.vpc,
    module.alb,
    module.orders_service_ecs
  ]
}