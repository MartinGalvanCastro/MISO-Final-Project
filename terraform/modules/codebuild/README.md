# CodeBuild Terraform Module

This module creates an AWS CodeBuild project for CI/CD pipelines that builds Docker images and pushes them to Amazon ECR.

## Features

- **Docker Image Building**: Automated Docker image builds with multi-stage support
- **ECR Integration**: Automatic login and push to ECR repositories
- **Versioning**: Multiple tagging strategies (latest, version, commit hash, build number)
- **IAM Roles**: Properly scoped IAM roles and policies for ECR access
- **CloudWatch Logging**: Centralized logging with configurable retention
- **Monitoring**: CloudWatch alarms for build failures
- **Flexible Configuration**: Support for various source types and build environments

## Usage

### Basic Usage
```hcl
module "orders_service_build" {
  source = "./modules/codebuild"

  project_name = "orders-service-build"
  service_name = "orders"
  description  = "Build pipeline for orders service"

  # ECR Integration
  ecr_repository_arn = module.orders_ecr.repository_arn
  ecr_repository_url = module.orders_ecr.repository_url

  # Source Configuration
  source_type     = "GITHUB"
  source_location = "https://github.com/your-org/orders-service.git"

  common_tags = var.common_tags
}
```

### Advanced Configuration
```hcl
module "production_service_build" {
  source = "./modules/codebuild"

  project_name = "production-service-build"
  service_name = "production-service"
  description  = "Production CI/CD pipeline"

  # ECR Integration
  ecr_repository_arn = aws_ecr_repository.production.arn
  ecr_repository_url = aws_ecr_repository.production.repository_url

  # Build Configuration
  compute_type    = "BUILD_GENERAL1_MEDIUM"
  build_image     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
  privileged_mode = true

  # Source Configuration
  source_type     = "GITHUB"
  source_location = "https://github.com/your-org/production-service.git"
  source_version  = "main"

  # Custom buildspec
  buildspec_file = file("${path.module}/custom-buildspec.yml")

  # Environment Variables
  environment_variables = {
    NODE_ENV     = "production"
    VERSION_TAG  = "v2.1.0"
    SERVICE_NAME = "production-service"
  }

  # Logging Configuration
  log_retention_days = 30

  # Monitoring
  enable_build_failure_alarm = true
  alarm_actions             = [aws_sns_topic.alerts.arn]

  common_tags = {
    Environment = "production"
    Team        = "platform"
    Project     = "main-app"
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
| [aws_codebuild_project.project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_iam_role.codebuild_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.codebuild_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_cloudwatch_log_group.codebuild_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.build_failure_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the CodeBuild project | `string` | n/a | yes |
| service_name | Name of the service this CodeBuild project is for | `string` | n/a | yes |
| ecr_repository_arn | ARN of the ECR repository to push images to | `string` | n/a | yes |
| ecr_repository_url | URL of the ECR repository to push images to | `string` | n/a | yes |
| description | Description of the CodeBuild project | `string` | `"CodeBuild project for CI/CD pipeline"` | no |
| compute_type | Information about the compute resources the build project will use | `string` | `"BUILD_GENERAL1_SMALL"` | no |
| build_image | Docker image to use for this build project | `string` | `"aws/codebuild/amazonlinux2-x86_64-standard:5.0"` | no |
| image_pull_credentials_type | Type of credentials AWS CodeBuild uses to pull images | `string` | `"CODEBUILD"` | no |
| privileged_mode | Whether to enable running the Docker daemon inside a Docker container | `bool` | `true` | no |
| default_image_tag | Default image tag to use when building images | `string` | `"latest"` | no |
| source_type | Type of repository that contains the source code to be built | `string` | `"GITHUB"` | no |
| source_location | Location of the source code from git or s3 | `string` | `null` | no |
| source_version | Version of the build input to be built for this project | `string` | `null` | no |
| git_clone_depth | Truncate git history to this many commits | `number` | `1` | no |
| buildspec_file | Build specification to use for this build project's related builds | `string` | `null` | no |
| dockerfile_path | Path to the Dockerfile relative to the source root | `string` | `"."` | no |
| environment_variables | A map of environment variables to make available to the build environment | `map(string)` | `{}` | no |
| artifacts_type | Build output artifact's type | `string` | `"NO_ARTIFACTS"` | no |
| artifacts_location | Information about the build output artifact location | `string` | `null` | no |
| artifacts_bucket_arn | ARN of the S3 bucket for build artifacts | `string` | `null` | no |
| vpc_id | ID of the VPC within which to run builds | `string` | `null` | no |
| subnet_ids | List of subnet IDs within which to run builds | `list(string)` | `[]` | no |
| security_group_ids | List of security group IDs to assign to running builds | `list(string)` | `[]` | no |
| log_retention_days | Number of days to retain build logs | `number` | `14` | no |
| enable_build_failure_alarm | Enable CloudWatch alarm for build failures | `bool` | `true` | no |
| alarm_actions | List of ARNs to notify when alarm triggers | `list(string)` | `[]` | no |
| common_tags | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| project_name | Name of the CodeBuild project |
| project_arn | ARN of the CodeBuild project |
| project_id | Name of the CodeBuild project |
| project_badge_url | URL of the build badge when badge_enabled is true |
| service_role_arn | ARN of the CodeBuild service role |
| service_role_name | Name of the CodeBuild service role |
| log_group_name | Name of the CloudWatch log group |
| log_group_arn | ARN of the CloudWatch log group |
| build_failure_alarm_arn | ARN of the build failure alarm |
| project_info | Complete CodeBuild project information |
| build_commands | AWS CLI commands to start builds |

## Build Process

### Default Build Workflow

1. **Pre-build Phase**:
   - Login to Amazon ECR
   - Set up environment variables
   - Generate image tags (latest, version, commit hash, build number)

2. **Build Phase**:
   - Build Docker image using provided Dockerfile
   - Tag image with multiple tags for different use cases

3. **Post-build Phase**:
   - Push all tagged images to ECR
   - Log image URIs for reference

### Image Tagging Strategy

The module automatically creates multiple tags for each build:

- **`latest`**: Always points to the most recent successful build
- **`v1.0.0`**: Version tag (configurable via `VERSION_TAG` environment variable)
- **`abcd123`**: Git commit hash (first 7 characters)
- **`build-42`**: Build number from CodeBuild

### Environment Variables

The build environment includes several pre-configured variables:

- `AWS_DEFAULT_REGION`: Current AWS region
- `AWS_ACCOUNT_ID`: Current AWS account ID
- `ECR_REPOSITORY_URI`: Target ECR repository URL
- `IMAGE_TAG`: Default image tag
- Custom variables from `environment_variables` input

## IAM Permissions

The module creates an IAM role with the following permissions:

### CloudWatch Logs
- `logs:CreateLogGroup`
- `logs:CreateLogStream`
- `logs:PutLogEvents`

### ECR Access
- `ecr:GetAuthorizationToken` (for login)
- `ecr:BatchCheckLayerAvailability`
- `ecr:GetDownloadUrlForLayer`
- `ecr:BatchGetImage`
- `ecr:CompleteLayerUpload` (for push)
- `ecr:UploadLayerPart`
- `ecr:InitiateLayerUpload`
- `ecr:PutImage`

### S3 Access (if artifacts bucket specified)
- `s3:GetObject`
- `s3:GetObjectVersion`
- `s3:PutObject`

## Monitoring

### CloudWatch Alarms

The module optionally creates CloudWatch alarms for:

- **Build Failures**: Triggers when builds fail (configurable threshold)

### Metrics Available

- `FailedBuilds`: Number of failed builds
- `SucceededBuilds`: Number of successful builds
- `Duration`: Build duration in seconds

## Buildspec Configuration

### Using Default Template

If no custom buildspec is provided, the module uses a template that:

- Supports both orders and inventory services
- Uses configurable Dockerfile paths
- Implements the standard tagging strategy
- Includes comprehensive logging

### Custom Buildspec

You can provide a custom buildspec file:

```hcl
buildspec_file = file("${path.module}/custom-buildspec.yml")
```

Example custom buildspec:

```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI

  build:
    commands:
      - echo Building Docker image...
      - docker build -t $ECR_REPOSITORY_URI:$VERSION_TAG .

  post_build:
    commands:
      - echo Pushing Docker image...
      - docker push $ECR_REPOSITORY_URI:$VERSION_TAG
```

## Integration Examples

### Triggering Builds

#### Manual Build Start
```bash
aws codebuild start-build --project-name orders-service-build
```

#### Build with Custom Version
```bash
aws codebuild start-build \
  --project-name orders-service-build \
  --environment-variables-override name=VERSION_TAG,value=v2.0.0
```

#### Build with Multiple Environment Variables
```bash
aws codebuild start-build \
  --project-name orders-service-build \
  --environment-variables-override \
    name=VERSION_TAG,value=v2.0.0 \
    name=BUILD_ENV,value=production
```

### GitHub Integration

For GitHub repositories, you can set up webhooks to trigger builds automatically:

```hcl
resource "aws_codebuild_webhook" "orders_service" {
  project_name = module.orders_service_build.project_name

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "refs/heads/main"
    }
  }
}
```

### With CodePipeline

```hcl
resource "aws_codepipeline" "pipeline" {
  name     = "orders-service-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"

      configuration = {
        ProjectName = module.orders_service_build.project_name
      }
    }
  }
}
```

## Best Practices

### Security
- Use least-privilege IAM policies
- Enable VPC configuration for sensitive builds
- Use encrypted S3 buckets for artifacts
- Regularly rotate access keys

### Performance
- Choose appropriate compute type for your builds
- Use Docker layer caching when possible
- Minimize Dockerfile layers
- Use `.dockerignore` to exclude unnecessary files

### Cost Optimization
- Use smaller compute types when sufficient
- Set appropriate log retention periods
- Clean up old build artifacts
- Monitor build duration and optimize

### Monitoring
- Enable CloudWatch alarms for build failures
- Set up notifications for critical builds
- Monitor build duration trends
- Use CloudWatch Insights for log analysis

## Troubleshooting

### Common Issues

1. **ECR Permission Denied**
   - Verify ECR repository ARN is correct
   - Check IAM role has ECR permissions
   - Ensure repository exists in the same region

2. **Docker Build Failures**
   - Check Dockerfile syntax
   - Verify base image availability
   - Review build logs in CloudWatch

3. **Source Access Issues**
   - Verify source location URL
   - Check GitHub repository permissions
   - Confirm branch/tag exists

### Debugging Commands

```bash
# View build logs
aws logs get-log-events \
  --log-group-name /aws/codebuild/orders-service-build \
  --log-stream-name <build-id>

# List recent builds
aws codebuild list-builds-for-project \
  --project-name orders-service-build \
  --sort-order DESCENDING

# Get build details
aws codebuild batch-get-builds --ids <build-id>
```