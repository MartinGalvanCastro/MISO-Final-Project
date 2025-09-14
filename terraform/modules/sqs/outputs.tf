# Queue Outputs
output "queue_id" {
  description = "The URL for the created Amazon SQS queue"
  value       = aws_sqs_queue.queue.id
}

output "queue_arn" {
  description = "The ARN of the SQS queue"
  value       = aws_sqs_queue.queue.arn
}

output "queue_url" {
  description = "The URL for the created Amazon SQS queue"
  value       = aws_sqs_queue.queue.url
}

output "queue_name" {
  description = "The name of the SQS queue"
  value       = aws_sqs_queue.queue.name
}

# Dead Letter Queue Outputs
output "dead_letter_queue_id" {
  description = "The URL for the created Amazon SQS dead letter queue"
  value       = var.enable_dead_letter_queue ? aws_sqs_queue.dead_letter_queue[0].id : null
}

output "dead_letter_queue_arn" {
  description = "The ARN of the SQS dead letter queue"
  value       = var.enable_dead_letter_queue ? aws_sqs_queue.dead_letter_queue[0].arn : null
}

output "dead_letter_queue_url" {
  description = "The URL for the created Amazon SQS dead letter queue"
  value       = var.enable_dead_letter_queue ? aws_sqs_queue.dead_letter_queue[0].url : null
}

output "dead_letter_queue_name" {
  description = "The name of the SQS dead letter queue"
  value       = var.enable_dead_letter_queue ? aws_sqs_queue.dead_letter_queue[0].name : null
}

# CloudWatch Alarm Outputs
output "queue_depth_alarm_arn" {
  description = "The ARN of the queue depth CloudWatch alarm"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.queue_depth_alarm[0].arn : null
}

output "dlq_depth_alarm_arn" {
  description = "The ARN of the dead letter queue depth CloudWatch alarm"
  value       = var.enable_dead_letter_queue && var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.dlq_depth_alarm[0].arn : null
}

# Comprehensive Queue Information
output "queue_info" {
  description = "Complete queue information"
  value = {
    # Main queue
    queue = {
      id   = aws_sqs_queue.queue.id
      arn  = aws_sqs_queue.queue.arn
      url  = aws_sqs_queue.queue.url
      name = aws_sqs_queue.queue.name
    }

    # Dead letter queue
    dead_letter_queue = var.enable_dead_letter_queue ? {
      id   = aws_sqs_queue.dead_letter_queue[0].id
      arn  = aws_sqs_queue.dead_letter_queue[0].arn
      url  = aws_sqs_queue.dead_letter_queue[0].url
      name = aws_sqs_queue.dead_letter_queue[0].name
    } : null

    # Configuration
    configuration = {
      fifo_queue                    = var.fifo_queue
      enable_dead_letter_queue     = var.enable_dead_letter_queue
      max_receive_count            = var.max_receive_count
      visibility_timeout_seconds   = var.visibility_timeout_seconds
      message_retention_seconds    = var.message_retention_seconds
      enable_cloudwatch_alarms     = var.enable_cloudwatch_alarms
    }

    # Service information
    service_name = var.service_name
  }
}

# Queue Configuration for Application Use
output "queue_config" {
  description = "Queue configuration for application integration"
  value = {
    queue_url                = aws_sqs_queue.queue.url
    queue_arn               = aws_sqs_queue.queue.arn
    dead_letter_queue_url   = var.enable_dead_letter_queue ? aws_sqs_queue.dead_letter_queue[0].url : null
    region                  = data.aws_region.current.name
    visibility_timeout      = var.visibility_timeout_seconds
    max_receive_count       = var.max_receive_count
  }
}

# Data source for current region
data "aws_region" "current" {}