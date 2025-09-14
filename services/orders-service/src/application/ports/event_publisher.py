from abc import ABC, abstractmethod
from typing import Any


class EventPublisher(ABC):
    
    @abstractmethod
    async def publish(self, event_type: str, payload: dict[str, Any]) -> None:
        """
        Publish a domain event
        Args:
            event_type: Type of event (e.g., "OrderCreated")
            payload: Event data
        """
        pass