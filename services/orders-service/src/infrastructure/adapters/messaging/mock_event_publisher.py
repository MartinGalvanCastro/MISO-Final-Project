import logging
from typing import Any

from src.application.ports.event_publisher import EventPublisher

logger = logging.getLogger(__name__)


class MockEventPublisher(EventPublisher):
    """Mock event publisher for local testing without SQS"""
    
    async def publish(self, event_type: str, payload: dict[str, Any]) -> None:
        """
        Log event instead of publishing to SQS
        """
        logger.info(f"[MOCK] Publishing event: {event_type}")
        logger.debug(f"[MOCK] Event payload: {payload}")