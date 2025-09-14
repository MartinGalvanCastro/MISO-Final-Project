# SQS Terraform Module

This module creates an AWS SQS (Simple Queue Service) queue with an optional dead letter queue, CloudWatch monitoring, and comprehensive configuration options.

## Features

- Standard or FIFO SQS queue creation
- Optional dead letter queue (DLQ) with configurable retry policy
- CloudWatch alarms for queue depth monitoring
- Configurable message retention and visibility timeout
- Optional server-side encryption with KMS
- Long polling support for cost optimization
- Comprehensive queue access policies
- Production-ready monitoring and alerting

## Usage

### Basic Usage
```hcl
module "orders_queue" {
  source = "./modules/sqs"

  queue_name   = "orders-processing"
  service_name = "orders"
  description  = "Queue for processing order events"

  common_tags = {
    Environment = "production"
    Project     = "ecommerce"
  }
}
```

### Advanced Configuration
```hcl
module "high_volume_queue" {
  source = "./modules/sqs"

  queue_name   = "high-volume-events"
  service_name = "event-processor"
  description  = "High-volume event processing queue"

  # Queue Configuration
  visibility_timeout_seconds = 900  # 15 minutes
  message_retention_seconds  = 604800  # 7 days
  receive_wait_time_seconds  = 20   # Enable long polling
  max_message_size          = 262144 # 256KB

  # Dead Letter Queue
  enable_dead_letter_queue = true
  max_receive_count        = 5

  # Monitoring
  enable_cloudwatch_alarms     = true
  queue_depth_alarm_threshold  = 1000
  dlq_depth_alarm_threshold   = 10

  # Encryption
  kms_master_key_id = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-a123-456a-a12b-a123b4cd56ef"

  common_tags = {
    Environment = "production"
    Project     = "ecommerce"
    CostCenter  = "engineering"
  }
}
```

### FIFO Queue
```hcl
module "fifo_queue" {
  source = "./modules/sqs"

  queue_name = "orders-fifo.fifo"  # Must end with .fifo
  service_name = "orders"
  description = "FIFO queue for order processing"

  # FIFO Configuration
  fifo_queue                  = true
  content_based_deduplication = true

  common_tags = var.common_tags
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
| [aws_sqs_queue.queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.dead_letter_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.queue_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_sqs_queue_policy.dlq_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_cloudwatch_metric_alarm.queue_depth_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.dlq_depth_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| queue_name | Name of the SQS queue | `string` | n/a | yes |
| service_name | Name of the service this queue is for | `string` | n/a | yes |
| description | Description of the SQS queue | `string` | `"SQS queue"` | no |
| delay_seconds | The time in seconds that the delivery of all messages in the queue will be delayed | `number` | `0` | no |
| max_message_size | The limit of how many bytes a message can contain before Amazon SQS rejects it | `number` | `262144` | no |
| message_retention_seconds | The number of seconds Amazon SQS retains a message | `number` | `1209600` | no |
| receive_wait_time_seconds | The time for which a ReceiveMessage call will wait for a message to arrive | `number` | `0` | no |
| visibility_timeout_seconds | The visibility timeout for the queue | `number` | `30` | no |
| enable_dead_letter_queue | Enable dead letter queue for failed messages | `bool` | `true` | no |
| max_receive_count | The number of times a message is delivered to the source queue before being moved to the dead-letter queue | `number` | `3` | no |
| dlq_message_retention_seconds | The number of seconds Amazon SQS retains a message in the dead letter queue | `number` | `1209600` | no |
| fifo_queue | Boolean designating a FIFO queue | `bool` | `false` | no |
| content_based_deduplication | Enables content-based deduplication for FIFO queues | `bool` | `false` | no |
| kms_master_key_id | The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK | `string` | `null` | no |
| kms_data_key_reuse_period_seconds | The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages | `number` | `300` | no |
| queue_policy | JSON policy document for the queue | `string` | `null` | no |
| dlq_policy | JSON policy document for the dead letter queue | `string` | `null` | no |
| enable_cloudwatch_alarms | Enable CloudWatch alarms for queue monitoring | `bool` | `true` | no |
| queue_depth_alarm_threshold | Threshold for queue depth alarm | `number` | `100` | no |
| dlq_depth_alarm_threshold | Threshold for dead letter queue depth alarm | `number` | `1` | no |
| alarm_actions | List of ARNs to notify when alarm triggers | `list(string)` | `[]` | no |
| common_tags | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| queue_id | The URL for the created Amazon SQS queue |
| queue_arn | The ARN of the SQS queue |
| queue_url | The URL for the created Amazon SQS queue |
| queue_name | The name of the SQS queue |
| dead_letter_queue_id | The URL for the created Amazon SQS dead letter queue |
| dead_letter_queue_arn | The ARN of the SQS dead letter queue |
| dead_letter_queue_url | The URL for the created Amazon SQS dead letter queue |
| dead_letter_queue_name | The name of the SQS dead letter queue |
| queue_depth_alarm_arn | The ARN of the queue depth CloudWatch alarm |
| dlq_depth_alarm_arn | The ARN of the dead letter queue depth CloudWatch alarm |
| queue_info | Complete queue information |
| queue_config | Queue configuration for application integration |

## Queue Configuration Details

### Message Processing

- **Visibility Timeout**: Controls how long a message is invisible after being received
- **Message Retention**: How long messages are kept in the queue
- **Receive Wait Time**: Enable long polling to reduce costs and improve efficiency
- **Max Message Size**: Maximum size for individual messages (up to 256KB)

### Dead Letter Queue

When enabled, the dead letter queue:
- Captures messages that fail processing after `max_receive_count` attempts
- Helps identify and debug problematic messages
- Prevents infinite retry loops
- Maintains separate retention settings

### CloudWatch Monitoring

The module creates CloudWatch alarms for:
- **Queue Depth**: Alerts when too many messages are waiting
- **DLQ Depth**: Alerts when messages are failing to process

### Security

- **Encryption**: Optional server-side encryption with AWS KMS
- **Access Policies**: Configurable IAM policies for queue access
- **VPC Integration**: Queues can be accessed from VPC endpoints

## Best Practices

### Performance Optimization
```hcl
# Enable long polling to reduce costs and improve efficiency
receive_wait_time_seconds = 20

# Optimize visibility timeout based on processing time
visibility_timeout_seconds = 300  # 5 minutes for typical processing

# Use appropriate message retention
message_retention_seconds = 1209600  # 14 days (maximum)
```

### Error Handling
```hcl
# Configure dead letter queue for failed messages
enable_dead_letter_queue = true
max_receive_count        = 3  # Retry 3 times before moving to DLQ

# Set up monitoring
enable_cloudwatch_alarms     = true
queue_depth_alarm_threshold  = 100   # Alert if queue backs up
dlq_depth_alarm_threshold   = 1     # Alert on any DLQ messages
```

### Security
```hcl
# Enable encryption for sensitive data
kms_master_key_id = "arn:aws:kms:region:account:key/key-id"

# Use custom access policies for fine-grained control
queue_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::account:role/service-role"
      }
      Action = [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage"
      ]
      Resource = "*"
    }
  ]
})
```

## Integration Examples

### With Application Code (Python)
```python
import boto3

# Queue configuration from Terraform output
QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/123456789012/orders-queue"

sqs = boto3.client('sqs')

# Send message
response = sqs.send_message(
    QueueUrl=QUEUE_URL,
    MessageBody=json.dumps(order_data)
)

# Receive messages
messages = sqs.receive_message(
    QueueUrl=QUEUE_URL,
    WaitTimeSeconds=20,  # Long polling
    MaxNumberOfMessages=10
)
```

### With Lambda Function
```hcl
resource "aws_lambda_event_source_mapping" "queue_trigger" {
  event_source_arn = module.orders_queue.queue_arn
  function_name    = aws_lambda_function.processor.arn
  batch_size       = 10
}
```

## Cost Optimization

- **Long Polling**: Use `receive_wait_time_seconds = 20` to reduce API calls
- **Message Batching**: Send/receive messages in batches when possible
- **Appropriate Retention**: Set `message_retention_seconds` based on actual needs
- **Dead Letter Queues**: Prevent infinite retries and associated costs

## Monitoring and Troubleshooting

### Key Metrics to Monitor
- `ApproximateNumberOfVisibleMessages`: Messages waiting to be processed
- `ApproximateNumberOfMessagesNotVisible`: Messages being processed
- `ApproximateAgeOfOldestMessage`: How long the oldest message has been waiting

### Common Issues
- **Messages stuck in processing**: Check visibility timeout settings
- **Messages going to DLQ**: Review application error handling
- **High costs**: Enable long polling and optimize message retention