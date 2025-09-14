from abc import ABC, abstractmethod
from typing import Optional, List, Dict
from src.domain.models.inventory import InventoryItem


class InventoryRepository(ABC):

    @abstractmethod
    async def find_by_product_id(self, product_id: str) -> Optional[InventoryItem]:
        pass

    @abstractmethod
    async def find_by_product_ids(self, product_ids: List[str]) -> Dict[str, InventoryItem]:
        pass

    @abstractmethod
    async def save(self, item: InventoryItem) -> InventoryItem:
        pass

    @abstractmethod
    async def save_all(self, items: List[InventoryItem]) -> List[InventoryItem]:
        pass