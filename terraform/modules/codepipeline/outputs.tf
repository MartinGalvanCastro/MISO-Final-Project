output "pipeline_name" {
  description = "Name of the created CodePipeline"
  value       = aws_codepipeline.pipeline.name
}

output "pipeline_arn" {
  description = "ARN of the created CodePipeline"
  value       = aws_codepipeline.pipeline.arn
}

output "pipeline_role_arn" {
  description = "ARN of the CodePipeline service role"
  value       = aws_iam_role.codepipeline_role.arn
}

output "pipeline_role_name" {
  description = "Name of the CodePipeline service role"
  value       = aws_iam_role.codepipeline_role.name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for the pipeline"
  value       = aws_cloudwatch_log_group.codepipeline_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for the pipeline"
  value       = aws_cloudwatch_log_group.codepipeline_logs.arn
}