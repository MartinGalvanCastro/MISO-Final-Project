from abc import ABC, abstractmethod

from src.domain.models.order import Order


class OrderRepository(ABC):
    
    @abstractmethod
    async def save(self, order: Order) -> Order:
        pass
    
    @abstractmethod
    async def find_all(self) -> list[Order]:
        pass
    
    @abstractmethod
    async def find_by_id(self, order_id: str) -> Order | None:
        pass