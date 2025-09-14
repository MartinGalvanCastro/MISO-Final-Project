# ECS Fargate Module

This Terraform module creates and manages an Amazon ECS Fargate service with auto-scaling, load balancing, and comprehensive monitoring capabilities. It supports both creating a new ECS cluster and deploying to an existing one.

## Features

- **ECS Fargate Service**: Serverless container orchestration
- **Auto Scaling**: CPU and memory-based scaling (configurable 3-6 replicas)
- **Health Checks**: Comprehensive container health monitoring
- **Security Groups**: Properly configured network access controls
- **IAM Roles**: Task execution and task roles with customizable policies
- **CloudWatch Logging**: Centralized log aggregation and retention
- **CloudWatch Alarms**: Proactive monitoring and alerting
- **Load Balancer Integration**: Seamless ALB target group association
- **ECS Exec Support**: Optional debugging capabilities

## Architecture

The module deploys the following resources:

- **ECS Cluster**: Container orchestration cluster (optional)
- **ECS Service**: Fargate service with desired task count
- **Task Definition**: Container specification with resource allocation
- **Auto Scaling Target**: Application Auto Scaling for dynamic scaling
- **Auto Scaling Policies**: CPU and memory-based scaling policies
- **Security Group**: Network access control for the service
- **IAM Roles**: Task execution and application roles
- **CloudWatch Log Group**: Centralized logging
- **CloudWatch Alarms**: High CPU and memory monitoring

## Usage

### Basic Usage

```hcl
module "orders_service" {
  source = "./modules/ecs-fargate"

  # Service Configuration
  service_name = "orders-service"
  cluster_name = "microservices-cluster"

  # Container Configuration
  container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/orders:latest"
  container_port  = 8001
  cpu             = 256
  memory          = 512

  # Networking
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  # Auto Scaling (3-6 replicas as specified)
  desired_count = 3
  min_capacity  = 3
  max_capacity  = 6

  common_tags = {
    Environment = "production"
    Service     = "orders"
  }
}
```

### Advanced Usage with ALB Integration

```hcl
module "inventory_service" {
  source = "./modules/ecs-fargate"

  # Service Configuration
  service_name = "inventory-service"
  cluster_name = "microservices-cluster"
  create_cluster = false  # Use existing cluster
  existing_cluster_id = "arn:aws:ecs:us-east-1:123456789012:cluster/microservices-cluster"
  existing_cluster_name = "microservices-cluster"

  # Container Configuration
  container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/inventory:v1.2.0"
  container_port  = 8002
  cpu             = 512
  memory          = 1024

  # Environment Variables
  environment_variables = {
    APP_NAME    = "inventory-service"
    PORT        = "8002"
    DEBUG       = "false"
    ENVIRONMENT = "production"
  }

  # Secrets from Parameter Store/Secrets Manager
  secrets = {
    DATABASE_URL = "arn:aws:ssm:us-east-1:123456789012:parameter/inventory/db-url"
    API_KEY      = "arn:aws:secretsmanager:us-east-1:123456789012:secret:inventory/api-key"
  }

  # Health Check Configuration
  health_check_command = ["CMD-SHELL", "curl -f http://localhost:8002/health || exit 1"]
  health_check_interval = 30
  health_check_timeout  = 5
  health_check_retries  = 3
  health_check_start_period = 60

  # Networking
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]
  alb_security_group_ids = ["sg-12345678"]

  # Load Balancer Integration
  target_group_arns = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/inventory-tg/1234567890123456"]

  # Auto Scaling Configuration
  desired_count = 4
  min_capacity  = 3
  max_capacity  = 6
  cpu_target_value    = 70
  memory_target_value = 80
  scale_in_cooldown   = 300
  scale_out_cooldown  = 300

  # Custom IAM Policies
  task_role_policy_statements = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      Resource = ["arn:aws:s3:::my-bucket/*"]
    }
  ]

  # Logging and Monitoring
  log_retention_days = 30
  enable_cloudwatch_alarms = true

  # Debugging
  enable_execute_command = true

  common_tags = {
    Environment = "production"
    Service     = "inventory"
    Team        = "backend"
  }
}
```

## Input Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `service_name` | Name of the ECS service | `string` |
| `cluster_name` | Name of the ECS cluster | `string` |
| `container_image` | Docker image for the container | `string` |
| `vpc_id` | VPC ID where the service will be deployed | `string` |
| `subnet_ids` | List of subnet IDs for the ECS service | `list(string)` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_cluster` | Whether to create a new ECS cluster or use existing one | `bool` | `true` |
| `existing_cluster_id` | ID of existing ECS cluster (if create_cluster is false) | `string` | `null` |
| `existing_cluster_name` | Name of existing ECS cluster (if create_cluster is false) | `string` | `null` |
| `container_port` | Port on which the container listens | `number` | `8000` |
| `cpu` | Number of CPU units for the task | `number` | `256` |
| `memory` | Amount of memory (MB) for the task | `number` | `512` |
| `platform_version` | Fargate platform version | `string` | `"LATEST"` |
| `desired_count` | Desired number of running tasks | `number` | `3` |
| `min_capacity` | Minimum number of tasks | `number` | `3` |
| `max_capacity` | Maximum number of tasks | `number` | `6` |
| `cpu_target_value` | Target CPU utilization percentage for auto scaling | `number` | `70` |
| `memory_target_value` | Target memory utilization percentage for auto scaling | `number` | `70` |
| `enable_execute_command` | Enable ECS Exec for debugging | `bool` | `false` |
| `log_retention_days` | Number of days to retain logs | `number` | `14` |
| `enable_cloudwatch_alarms` | Enable CloudWatch alarms for the service | `bool` | `true` |

## Outputs

### Service Information

| Name | Description |
|------|-------------|
| `service_id` | ID of the ECS service |
| `service_name` | Name of the ECS service |
| `service_arn` | ARN of the ECS service |
| `cluster_id` | ID of the ECS cluster |
| `cluster_name` | Name of the ECS cluster |
| `cluster_arn` | ARN of the ECS cluster |

### Task Definition

| Name | Description |
|------|-------------|
| `task_definition_arn` | ARN of the task definition |
| `task_definition_family` | Family of the task definition |
| `task_definition_revision` | Revision of the task definition |

### IAM Roles

| Name | Description |
|------|-------------|
| `task_execution_role_arn` | ARN of the task execution role |
| `task_role_arn` | ARN of the task role |

### Networking

| Name | Description |
|------|-------------|
| `security_group_id` | ID of the ECS service security group |

### Auto Scaling

| Name | Description |
|------|-------------|
| `autoscaling_target_resource_id` | Resource ID of the autoscaling target |
| `cpu_scaling_policy_arn` | ARN of the CPU scaling policy |
| `memory_scaling_policy_arn` | ARN of the memory scaling policy |

### Monitoring

| Name | Description |
|------|-------------|
| `log_group_name` | Name of the CloudWatch log group |
| `log_group_arn` | ARN of the CloudWatch log group |
| `high_cpu_alarm_arn` | ARN of the high CPU alarm |
| `high_memory_alarm_arn` | ARN of the high memory alarm |

### Complete Service Information

| Name | Description |
|------|-------------|
| `service_info` | Complete ECS service information object |
| `ecs_commands` | Useful ECS CLI commands for service management |

## CPU and Memory Configurations

### Valid CPU Values (in CPU units)
- 256 (0.25 vCPU)
- 512 (0.5 vCPU)
- 1024 (1 vCPU)
- 2048 (2 vCPU)
- 4096 (4 vCPU)

### Valid Memory Values (in MB)
The memory value must be compatible with the chosen CPU value:

| CPU | Valid Memory Values |
|-----|---------------------|
| 256 | 512, 1024, 2048 |
| 512 | 1024-4096 (in 1GB increments) |
| 1024 | 2048-8192 (in 1GB increments) |
| 2048 | 4096-16384 (in 1GB increments) |
| 4096 | 8192-30720 (in 1GB increments) |

## Auto Scaling Behavior

The module implements target tracking scaling policies for both CPU and memory utilization:

- **Scale Out**: When average utilization exceeds target value
- **Scale In**: When average utilization drops below target value
- **Cooldown Periods**: Configurable cooldown to prevent rapid scaling
- **Replica Range**: Enforced min/max capacity as specified (3-6 replicas)

## Health Checks

The service supports comprehensive health checking:

- **Container Health Check**: Configurable command-based health checks
- **ALB Health Check**: Integration with Application Load Balancer health checks
- **ECS Service Health**: Built-in ECS service health monitoring

## Security

- **IAM Roles**: Separate task execution and task roles with least privilege
- **Security Groups**: Restrictive network access with configurable ingress rules
- **Secrets Management**: Integration with AWS Parameter Store and Secrets Manager
- **Network Isolation**: Deployment in private subnets with NAT gateway egress

## Monitoring and Logging

- **CloudWatch Logs**: Centralized logging with configurable retention
- **CloudWatch Alarms**: CPU and memory utilization monitoring
- **ECS Insights**: Container-level metrics and performance monitoring
- **Custom Metrics**: Support for application-specific metrics

## ECS Management Commands

The module outputs useful AWS CLI commands for service management:

```bash
# Describe service
aws ecs describe-services --cluster <cluster-name> --services <service-name>

# List tasks
aws ecs list-tasks --cluster <cluster-name> --service-name <service-name>

# Force new deployment
aws ecs update-service --cluster <cluster-name> --service <service-name> --force-new-deployment

# Scale service
aws ecs update-service --cluster <cluster-name> --service <service-name> --desired-count <count>

# View logs
aws logs tail <log-group-name> --follow

# Execute into task (if enabled)
aws ecs execute-command --cluster <cluster-name> --task <task-id> --container <container-name> --interactive --command /bin/bash
```

## Requirements

- Terraform >= 1.0
- AWS Provider >= 5.0
- Proper AWS credentials and permissions

## Tags

All resources support tagging through the `common_tags` variable. Additional service-specific tags are automatically applied.

## Notes

- The module is designed for Fargate launch type only
- Auto-scaling is configured for 3-6 replicas as per requirements
- Health checks are essential for proper load balancer integration
- ECS Exec requires additional IAM permissions for debugging access
- Log retention should be configured based on compliance requirements