# Dead Letter Queue
resource "aws_sqs_queue" "dead_letter_queue" {
  count = var.enable_dead_letter_queue ? 1 : 0

  name                      = "${var.queue_name}-dlq"
  message_retention_seconds = var.dlq_message_retention_seconds

  # Encryption
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds

  tags = merge(var.common_tags, {
    Name        = "${var.queue_name}-dlq"
    Service     = var.service_name
    Description = "Dead letter queue for ${var.queue_name}"
    Type        = "DLQ"
  })
}

# Main SQS Queue
resource "aws_sqs_queue" "queue" {
  name                      = var.queue_name
  delay_seconds             = var.delay_seconds
  max_message_size          = var.max_message_size
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = var.receive_wait_time_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # Dead letter queue configuration
  redrive_policy = var.enable_dead_letter_queue ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  # Encryption
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds

  # FIFO configuration
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.content_based_deduplication

  tags = merge(var.common_tags, {
    Name        = var.queue_name
    Service     = var.service_name
    Description = var.description
    Type        = var.fifo_queue ? "FIFO" : "Standard"
  })
}

# Queue Policy (if provided)
resource "aws_sqs_queue_policy" "queue_policy" {
  count     = var.queue_policy != null ? 1 : 0
  queue_url = aws_sqs_queue.queue.id
  policy    = var.queue_policy
}

# Dead Letter Queue Policy (if provided and DLQ is enabled)
resource "aws_sqs_queue_policy" "dlq_policy" {
  count     = var.enable_dead_letter_queue && var.dlq_policy != null ? 1 : 0
  queue_url = aws_sqs_queue.dead_letter_queue[0].id
  policy    = var.dlq_policy
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "queue_depth_alarm" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.queue_name}-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.queue_depth_alarm_threshold
  alarm_description   = "This metric monitors ${var.queue_name} queue depth"
  alarm_actions       = var.alarm_actions

  dimensions = {
    QueueName = aws_sqs_queue.queue.name
  }

  tags = merge(var.common_tags, {
    Name        = "${var.queue_name}-queue-depth-alarm"
    Service     = var.service_name
    Description = "CloudWatch alarm for ${var.queue_name} queue depth"
  })
}

resource "aws_cloudwatch_metric_alarm" "dlq_depth_alarm" {
  count = var.enable_dead_letter_queue && var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.queue_name}-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.dlq_depth_alarm_threshold
  alarm_description   = "This metric monitors ${var.queue_name} dead letter queue depth"
  alarm_actions       = var.alarm_actions

  dimensions = {
    QueueName = aws_sqs_queue.dead_letter_queue[0].name
  }

  tags = merge(var.common_tags, {
    Name        = "${var.queue_name}-dlq-depth-alarm"
    Service     = var.service_name
    Description = "CloudWatch alarm for ${var.queue_name} DLQ depth"
  })
}