output "orders_queue_url" {
  description = "URL of the orders SQS queue"
  value       = aws_sqs_queue.orders_queue.url
}

output "orders_queue_arn" {
  description = "ARN of the orders SQS queue"
  value       = aws_sqs_queue.orders_queue.arn
}

output "orders_queue_name" {
  description = "Name of the orders SQS queue"
  value       = aws_sqs_queue.orders_queue.name
}

output "orders_dlq_url" {
  description = "URL of the orders dead letter queue"
  value       = aws_sqs_queue.orders_dlq.url
}

output "orders_dlq_arn" {
  description = "ARN of the orders dead letter queue"
  value       = aws_sqs_queue.orders_dlq.arn
}

output "ecs_sqs_role_arn" {
  description = "ARN of the ECS task role for SQS access"
  value       = aws_iam_role.ecs_sqs_role.arn
}

output "sqs_access_policy_arn" {
  description = "ARN of the SQS access policy"
  value       = aws_iam_policy.sqs_access.arn
}