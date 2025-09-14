import json
import logging
from typing import Any

import boto3
from botocore.exceptions import ClientError

from src.application.ports.event_publisher import EventPublisher
from src.infrastructure.config.settings import settings

logger = logging.getLogger(__name__)


class SQSEventPublisher(EventPublisher):
    
    def __init__(self):
        self.queue_url = settings.SQS_QUEUE_URL
        
        # Configure client based on environment
        if settings.AWS_ENDPOINT_URL:  # LocalStack
            self.sqs_client = boto3.client(
                'sqs',
                region_name=settings.AWS_REGION,
                endpoint_url=settings.AWS_ENDPOINT_URL,
                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY
            )
        else:  # Real AWS
            self.sqs_client = boto3.client(
                'sqs',
                region_name=settings.AWS_REGION
            )

    async def publish(self, event_type: str, payload: dict[str, Any]) -> None:
        """
        Publish event to SQS queue
        """
        try:
            message = {
                "event_type": event_type,
                "payload": payload
            }
            
            response = self.sqs_client.send_message(
                QueueUrl=self.queue_url,
                MessageBody=json.dumps(message),
                MessageAttributes={
                    'EventType': {
                        'StringValue': event_type,
                        'DataType': 'String'
                    }
                }
            )
            
            logger.info(f"Published {event_type} event with MessageId: {response['MessageId']}")
            
        except ClientError as e:
            logger.error(f"AWS client error publishing event: {e}")
            raise
            
        except Exception as e:
            logger.error(f"Unexpected error publishing event: {str(e)}")
            raise