variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue"
  type        = number
  default     = 30  # 30 seconds default
}

variable "message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message"
  type        = number
  default     = 1209600  # 14 days (maximum for free tier)
}

variable "receive_wait_time_seconds" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive"
  type        = number
  default     = 20  # Long polling to reduce costs
}

variable "max_message_size" {
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it"
  type        = number
  default     = 262144  # 256 KB
}

variable "dlq_message_retention_seconds" {
  description = "Message retention period for dead letter queue"
  type        = number
  default     = 1209600  # 14 days
}

variable "max_receive_count" {
  description = "Maximum number of times a message can be received before being moved to DLQ"
  type        = number
  default     = 3
}