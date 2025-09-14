from abc import ABC, abstractmethod


class InventoryService(ABC):
    
    @abstractmethod
    async def check_stock(self, product_ids: list[str]) -> dict[str, int]:
        """
        Check stock availability for products
        Returns: Dict with product_id as key and available quantity as value
        """
        pass
    
    @abstractmethod
    async def reserve_stock(self, items: dict[str, int]) -> bool:
        """
        Reserve stock for order items
        Args: Dict with product_id as key and quantity to reserve as value
        Returns: True if reservation successful, False otherwise
        """
        pass