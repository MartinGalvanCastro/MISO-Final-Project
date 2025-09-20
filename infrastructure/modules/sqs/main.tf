# SQS Queue for Orders Processing
resource "aws_sqs_queue" "orders_queue" {
  name = "${var.project_name}-orders-queue"

  # Basic configuration
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  max_message_size          = var.max_message_size

  # Cost optimization - no encryption at rest for free tier
  # kms_master_key_id = "alias/aws/sqs"  # Commented out for cost savings

  tags = {
    Name        = "${var.project_name}-orders-queue"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "orders-processing"
  }
}

# Dead Letter Queue for failed messages
resource "aws_sqs_queue" "orders_dlq" {
  name = "${var.project_name}-orders-dlq"

  # DLQ configuration
  message_retention_seconds = var.dlq_message_retention_seconds

  tags = {
    Name        = "${var.project_name}-orders-dlq"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "orders-dead-letter"
  }
}

# Redrive Policy for main queue to DLQ
resource "aws_sqs_queue_redrive_policy" "orders_queue_redrive" {
  queue_url = aws_sqs_queue.orders_queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.orders_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

# IAM Policy for SQS access
resource "aws_iam_policy" "sqs_access" {
  name        = "${var.project_name}-sqs-access-policy"
  description = "Policy for ECS tasks to access SQS queues"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = [
          aws_sqs_queue.orders_queue.arn,
          aws_sqs_queue.orders_dlq.arn
        ]
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Role for ECS Tasks to access SQS
resource "aws_iam_role" "ecs_sqs_role" {
  name = "${var.project_name}-ecs-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Attach SQS policy to ECS role
resource "aws_iam_role_policy_attachment" "ecs_sqs_policy" {
  role       = aws_iam_role.ecs_sqs_role.name
  policy_arn = aws_iam_policy.sqs_access.arn
}

# Attach basic ECS task execution role policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_sqs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}