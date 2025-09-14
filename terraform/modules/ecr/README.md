# ECR Terraform Module

This module creates an AWS ECR (Elastic Container Registry) repository with configurable lifecycle policies.

## Features

- ECR repository with configurable image tag mutability
- Automatic image scanning on push
- Flexible lifecycle policies for image retention
- Support for versioned and latest image management
- Configurable repository access policies
- Comprehensive tagging support

## Usage

```hcl
module "orders_service_ecr" {
  source = "./modules/ecr"

  repository_name = "medisupply/orders-service"
  service_name    = "orders"
  description     = "Container repository for orders microservice"

  # Lifecycle policy configuration
  keep_versioned_images = 3
  keep_latest_images    = 1
  untagged_expiry_days  = 1

  # Tags
  common_tags = {
    Project     = "medisupply"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ecr_repository.repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_lifecycle_policy.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository_policy.repository_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| repository_name | Name of the ECR repository | `string` | n/a | yes |
| service_name | Name of the service this repository is for | `string` | n/a | yes |
| description | Description of the ECR repository | `string` | `"Container repository"` | no |
| image_tag_mutability | The tag mutability setting for the repository | `string` | `"MUTABLE"` | no |
| scan_on_push | Indicates whether images are scanned after being pushed | `bool` | `true` | no |
| enable_lifecycle_policy | Enable lifecycle policy for the repository | `bool` | `true` | no |
| keep_versioned_images | Number of versioned images to keep | `number` | `3` | no |
| keep_latest_images | Number of latest tagged images to keep | `number` | `1` | no |
| untagged_expiry_days | Number of days after which untagged images expire | `number` | `1` | no |
| version_tag_prefixes | List of tag prefixes for versioned images | `list(string)` | `["v"]` | no |
| latest_tag_prefixes | List of tag prefixes for latest images | `list(string)` | `["latest"]` | no |
| repository_policy | JSON policy document for repository access | `string` | `null` | no |
| common_tags | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_arn | ARN of the ECR repository |
| repository_url | URL of the ECR repository |
| repository_name | Name of the ECR repository |
| repository_registry_id | Registry ID of the ECR repository |
| lifecycle_policy_text | The text of the lifecycle policy |
| repository_info | Complete repository information |

## Lifecycle Policy

The module creates a lifecycle policy with the following rules:

1. **Versioned Images**: Keep the specified number of images tagged with version prefixes (default: `v*`, keep 3)
2. **Latest Images**: Keep the specified number of images tagged with latest prefixes (default: `latest`, keep 1)
3. **Untagged Images**: Delete untagged images after the specified number of days (default: 1 day)

### Example Lifecycle Policy Behavior

With default settings:
- Images tagged `v1.0.0`, `v1.0.1`, `v1.0.2` → kept (3 most recent)
- Images tagged `v0.9.0`, `v0.8.0` → deleted (older versions)
- Images tagged `latest` → kept (1 most recent)
- Untagged images older than 1 day → deleted

## Security

- Image scanning is enabled by default
- Repository is private by default
- Access controlled through IAM policies
- Optional repository policies for cross-account access

## Examples

### Basic Usage
```hcl
module "my_service_ecr" {
  source = "./modules/ecr"

  repository_name = "my-org/my-service"
  service_name    = "my-service"
}
```

### Advanced Configuration
```hcl
module "production_service_ecr" {
  source = "./modules/ecr"

  repository_name       = "my-org/production-service"
  service_name         = "production-service"
  image_tag_mutability = "IMMUTABLE"

  # Keep more images in production
  keep_versioned_images = 10
  keep_latest_images    = 2
  untagged_expiry_days  = 7

  # Custom tag prefixes
  version_tag_prefixes = ["v", "release-"]
  latest_tag_prefixes  = ["latest", "stable"]

  common_tags = {
    Environment = "production"
    Team        = "platform"
    Project     = "my-project"
  }
}
```