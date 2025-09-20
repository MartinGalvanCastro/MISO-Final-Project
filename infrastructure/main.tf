# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  project_name      = var.project_name
  github_repository = var.github_repository
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  project_name      = var.project_name
  environment       = var.environment
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.vpc.rds_security_group_id
  availability_zone = var.availability_zones[0]
}

# SQS Module
module "sqs" {
  source = "./modules/sqs"

  project_name = var.project_name
  environment  = var.environment
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"

  project_name          = var.project_name
  environment          = var.environment
  aws_region           = var.aws_region
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.public_subnet_ids
  security_group_ids   = [module.vpc.ecs_tasks_security_group_id]
  db_secret_arn        = module.rds.secret_arn
  sqs_access_policy_arn = module.sqs.sqs_access_policy_arn

  # ECR repositories
  ecr_repositories = module.ecr.ecr_repositories

  # Service Discovery namespace will be created within the module

  # ALB Target Groups
  orders_target_group_arn     = module.alb.target_groups.orders_service
  inventory_target_group_arn  = module.alb.target_groups.inventory_service
  prometheus_target_group_arn = module.alb.target_groups.prometheus
  grafana_target_group_arn    = module.alb.target_groups.grafana
  alb_listener_arn           = module.alb.listener_arn
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.public_subnet_ids
  alb_security_group_id = module.vpc.alb_security_group_id
}