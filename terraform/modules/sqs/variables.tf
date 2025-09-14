variable "queue_name" {
  description = "Name of the SQS queue"
  type        = string
}

variable "service_name" {
  description = "Name of the service this queue is for"
  type        = string
}

variable "description" {
  description = "Description of the SQS queue"
  type        = string
  default     = "SQS queue"
}

# Queue Configuration
variable "delay_seconds" {
  description = "The time in seconds that the delivery of all messages in the queue will be delayed"
  type        = number
  default     = 0

  validation {
    condition     = var.delay_seconds >= 0 && var.delay_seconds <= 900
    error_message = "Delay seconds must be between 0 and 900."
  }
}

variable "max_message_size" {
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it"
  type        = number
  default     = 262144

  validation {
    condition     = var.max_message_size >= 1024 && var.max_message_size <= 262144
    error_message = "Max message size must be between 1024 and 262144 bytes."
  }
}

variable "message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message"
  type        = number
  default     = 1209600 # 14 days

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "Message retention must be between 60 seconds and 1209600 seconds (14 days)."
  }
}

variable "receive_wait_time_seconds" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive"
  type        = number
  default     = 0

  validation {
    condition     = var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <= 20
    error_message = "Receive wait time must be between 0 and 20 seconds."
  }
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue"
  type        = number
  default     = 30

  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "Visibility timeout must be between 0 and 43200 seconds (12 hours)."
  }
}

# Dead Letter Queue Configuration
variable "enable_dead_letter_queue" {
  description = "Enable dead letter queue for failed messages"
  type        = bool
  default     = false
}

variable "max_receive_count" {
  description = "The number of times a message is delivered to the source queue before being moved to the dead-letter queue"
  type        = number
  default     = 3

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "Max receive count must be between 1 and 1000."
  }
}

variable "dlq_message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message in the dead letter queue"
  type        = number
  default     = 1209600 # 14 days

  validation {
    condition     = var.dlq_message_retention_seconds >= 60 && var.dlq_message_retention_seconds <= 1209600
    error_message = "DLQ message retention must be between 60 seconds and 1209600 seconds (14 days)."
  }
}

variable "dlq_max_receive_count" {
  description = "Maximum receive count for dead letter queue (not used, but kept for consistency)"
  type        = number
  default     = 1000
}

# FIFO Configuration
variable "fifo_queue" {
  description = "Boolean designating a FIFO queue"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO queues"
  type        = bool
  default     = false
}

# Encryption
variable "kms_master_key_id" {
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK"
  type        = string
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  description = "The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages"
  type        = number
  default     = 300

  validation {
    condition     = var.kms_data_key_reuse_period_seconds >= 60 && var.kms_data_key_reuse_period_seconds <= 86400
    error_message = "KMS data key reuse period must be between 60 seconds and 86400 seconds (24 hours)."
  }
}

# Policies
variable "queue_policy" {
  description = "JSON policy document for the queue"
  type        = string
  default     = null
}

variable "dlq_policy" {
  description = "JSON policy document for the dead letter queue"
  type        = string
  default     = null
}

# CloudWatch Monitoring
variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms for queue monitoring"
  type        = bool
  default     = true
}

variable "queue_depth_alarm_threshold" {
  description = "Threshold for queue depth alarm"
  type        = number
  default     = 100
}

variable "dlq_depth_alarm_threshold" {
  description = "Threshold for dead letter queue depth alarm"
  type        = number
  default     = 1
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}