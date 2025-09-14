# CodeBuild Project Outputs
output "project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.project.name
}

output "project_arn" {
  description = "ARN of the CodeBuild project"
  value       = aws_codebuild_project.project.arn
}

output "project_id" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.project.id
}

output "project_badge_url" {
  description = "URL of the build badge when badge_enabled is true"
  value       = aws_codebuild_project.project.badge_url
}

# IAM Role Outputs
output "service_role_arn" {
  description = "ARN of the CodeBuild service role"
  value       = aws_iam_role.codebuild_role.arn
}

output "service_role_name" {
  description = "Name of the CodeBuild service role"
  value       = aws_iam_role.codebuild_role.name
}

# CloudWatch Outputs
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.codebuild_logs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.codebuild_logs.arn
}

output "build_failure_alarm_arn" {
  description = "ARN of the build failure alarm"
  value       = var.enable_build_failure_alarm ? aws_cloudwatch_metric_alarm.build_failure_alarm[0].arn : null
}

# Complete Project Information
output "project_info" {
  description = "Complete CodeBuild project information"
  value = {
    name        = aws_codebuild_project.project.name
    arn         = aws_codebuild_project.project.arn
    service_role = aws_iam_role.codebuild_role.arn
    log_group   = aws_cloudwatch_log_group.codebuild_logs.name

    # Build Configuration
    compute_type    = var.compute_type
    build_image     = var.build_image
    privileged_mode = var.privileged_mode

    # Source Configuration
    source_type     = var.source_type
    source_location = var.source_location

    # Target Configuration
    ecr_repository_url = var.ecr_repository_url
    service_name      = var.service_name
  }
}

# Build Commands for Manual Execution
output "build_commands" {
  description = "AWS CLI commands to start builds"
  value = {
    start_build = "aws codebuild start-build --project-name ${aws_codebuild_project.project.name}"

    start_build_with_version = "aws codebuild start-build --project-name ${aws_codebuild_project.project.name} --environment-variables-override name=VERSION_TAG,value=v1.0.0"

    list_builds = "aws codebuild list-builds-for-project --project-name ${aws_codebuild_project.project.name}"

    get_logs = "aws logs get-log-events --log-group-name ${aws_cloudwatch_log_group.codebuild_logs.name} --log-stream-name <build-id>"
  }
}