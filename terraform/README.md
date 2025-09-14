# Terraform Infrastructure

This directory contains Terraform configuration for the MediSupply microservices infrastructure using a modular approach.

## Architecture Overview

The infrastructure is organized using Terraform modules for clean separation and reusability:

```
terraform/
├── main.tf                    # Root module - orchestrates resources
├── variables.tf              # Root module variables
├── outputs.tf               # Root module outputs
├── terraform.tfvars.example # Example configuration
├── README.md                # This file
└── modules/
    ├── ecr/                 # ECR module for container repositories
    │   ├── main.tf          # ECR resources
    │   ├── variables.tf     # ECR module variables
    │   ├── outputs.tf       # ECR module outputs
    │   └── README.md        # ECR module documentation
    └── sqs/                 # SQS module for message queues
        ├── main.tf          # SQS resources
        ├── variables.tf     # SQS module variables
        ├── outputs.tf       # SQS module outputs
        └── README.md        # SQS module documentation
```

## Resources Created

### ECR Repositories (via ECR Module)
- **Orders Service**: `medisupply/orders-service`
- **Inventory Service**: `medisupply/inventory-service`

### SQS Queues (via SQS Module)
- **Orders Queue**: `orders-queue` for publishing order events

### Features
- **Modular Design**: Each AWS service has its own reusable module
- **Container Registry (ECR)**:
  - Image scanning enabled for security
  - Configurable lifecycle policies (keep 3 versions, 1 latest)
  - Automatic cleanup of untagged images
- **Message Queuing (SQS)**:
  - Simple event publishing queue
  - CloudWatch monitoring and alarms
  - Long polling for cost optimization
  - Optional encryption with KMS
- **Flexible Configuration**: All settings configurable via variables
- **Comprehensive Outputs**: Detailed information for CI/CD integration

## Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed

### Quick Start
```bash
cd terraform

# Initialize Terraform
terraform init

# Copy and customize configuration
cp terraform.tfvars.example terraform.tfvars

# Plan the infrastructure
terraform plan

# Apply the infrastructure
terraform apply
```

### Destroy Infrastructure
```bash
terraform destroy
```

## Configuration

### Root Module Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| `aws_region` | AWS region for resources | `string` | `us-east-1` | no |
| `project_name` | Name of the project | `string` | `medisupply` | no |
| `environment` | Environment name | `string` | `development` | no |
| `orders_service_repo_name` | Orders service ECR repo name | `string` | `medisupply/orders-service` | no |
| `inventory_service_repo_name` | Inventory service ECR repo name | `string` | `medisupply/inventory-service` | no |
| `ecr_image_tag_mutability` | ECR image tag mutability | `string` | `MUTABLE` | no |
| `ecr_scan_on_push` | Enable image scanning on push | `bool` | `true` | no |
| `ecr_keep_versioned_images` | Number of versioned images to keep | `number` | `3` | no |
| `ecr_keep_latest_images` | Number of latest images to keep | `number` | `1` | no |
| `ecr_untagged_expiry_days` | Days before untagged images expire | `number` | `1` | no |
| `common_tags` | Common tags for all resources | `map(string)` | See variables.tf | no |

### Environment-Specific Configuration

Create different `.tfvars` files for each environment:

```bash
# Development
cp terraform.tfvars.example terraform.tfvars

# Staging
cp terraform.tfvars.example staging.tfvars
# Edit staging.tfvars with staging-specific values

# Production
cp terraform.tfvars.example production.tfvars
# Edit production.tfvars with production-specific values
```

Deploy to specific environments:
```bash
terraform apply -var-file="staging.tfvars"
terraform apply -var-file="production.tfvars"
```

## Outputs

The root module provides comprehensive outputs for integration:

### Individual Repository Outputs
- `orders_service_ecr_repository_url`
- `orders_service_ecr_repository_arn`
- `inventory_service_ecr_repository_url`
- `inventory_service_ecr_repository_arn`

### Comprehensive Outputs
- `ecr_repositories` - Complete information for both repositories
- `ecr_registry_info` - Registry information optimized for CI/CD

### Usage Example
```bash
# Get all repository information
terraform output ecr_repositories

# Get CI/CD-friendly output
terraform output ecr_registry_info
```

## Modules

### ECR Module (`./modules/ecr`)

A reusable module for creating ECR repositories with lifecycle policies.

**Features:**
- Configurable lifecycle policies
- Image scanning configuration
- Repository access policies
- Comprehensive tagging support

**Usage:**
```hcl
module "my_service_ecr" {
  source = "./modules/ecr"

  repository_name       = "my-org/my-service"
  service_name         = "my-service"
  keep_versioned_images = 5
  keep_latest_images    = 2

  common_tags = var.common_tags
}
```

See `modules/ecr/README.md` for detailed documentation.

### SQS Module (`./modules/sqs`)

A reusable module for creating SQS queues with dead letter queues and monitoring.

**Features:**
- Standard and FIFO queue support
- Optional dead letter queue (disabled by default)
- CloudWatch alarms for monitoring
- Optional KMS encryption
- Long polling configuration

**Usage:**
```hcl
module "my_service_sqs" {
  source = "./modules/sqs"

  queue_name   = "my-service-events"
  service_name = "my-service"
  description  = "Event publishing queue"

  # Simple event publishing - no DLQ needed
  enable_dead_letter_queue = false

  # Enable monitoring
  enable_cloudwatch_alarms = true
  queue_depth_alarm_threshold = 200

  common_tags = var.common_tags
}
```

See `modules/sqs/README.md` for detailed documentation.

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Get ECR Registry Info
  run: |
    REGISTRY_INFO=$(terraform output -json ecr_registry_info)
    echo "REGISTRY_URL=$(echo $REGISTRY_INFO | jq -r '.repositories.orders_service.url')" >> $GITHUB_ENV

- name: Build and Push
  run: |
    docker build -t $REGISTRY_URL:$GITHUB_SHA .
    docker push $REGISTRY_URL:$GITHUB_SHA
```

### Docker Commands
```bash
# Get repository URLs from Terraform
ORDERS_REPO=$(terraform output -raw orders_service_ecr_repository_url)
INVENTORY_REPO=$(terraform output -raw inventory_service_ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ORDERS_REPO

# Build and push orders service
docker build -t orders-service:latest services/orders-service/
docker tag orders-service:latest $ORDERS_REPO:latest
docker tag orders-service:latest $ORDERS_REPO:v1.0.0
docker push $ORDERS_REPO:latest
docker push $ORDERS_REPO:v1.0.0

# Build and push inventory service
docker build -t inventory-service:latest services/inventory-service/
docker tag inventory-service:latest $INVENTORY_REPO:latest
docker tag inventory-service:latest $INVENTORY_REPO:v1.0.0
docker push $INVENTORY_REPO:latest
docker push $INVENTORY_REPO:v1.0.0
```

## Best Practices

### Module Design
- Each AWS service has its own module
- Modules are reusable across environments
- Clear separation of concerns
- Comprehensive variable validation

### Lifecycle Management
- Version your infrastructure code
- Use separate state files per environment
- Tag all resources consistently
- Monitor costs with lifecycle policies

### Security
- Enable image scanning on all repositories
- Use least privilege IAM policies
- Keep repositories private by default
- Regular security scanning and updates

## Adding New Services

To add a new microservice:

1. **Use the existing ECR module:**
   ```hcl
   module "new_service_ecr" {
     source = "./modules/ecr"

     repository_name = "medisupply/new-service"
     service_name    = "new-service"
     description     = "Container repository for new microservice"

     common_tags = merge(var.common_tags, {
       Service = "new-service"
     })
   }
   ```

2. **Add outputs for the new service:**
   ```hcl
   output "new_service_ecr_repository_url" {
     description = "URL of the new service ECR repository"
     value       = module.new_service_ecr.repository_url
   }
   ```

3. **Update the comprehensive outputs:**
   ```hcl
   output "ecr_repositories" {
     description = "Map of all ECR repositories created"
     value = {
       orders_service    = module.orders_service_ecr.repository_info
       inventory_service = module.inventory_service_ecr.repository_info
       new_service      = module.new_service_ecr.repository_info
     }
   }
   ```

## Cost Optimization

- **Lifecycle Policies**: Automatically clean up old images
- **Image Scanning**: Included in AWS ECR pricing
- **Regional Deployment**: Deploy in regions closest to your users
- **Monitoring**: Use AWS Cost Explorer to track ECR costs