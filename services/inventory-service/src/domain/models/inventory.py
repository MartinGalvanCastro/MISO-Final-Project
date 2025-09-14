from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class InventoryItem:
    product_id: str
    available_quantity: int
    reserved_quantity: int = 0
    updated_at: Optional[datetime] = None

    @property
    def total_quantity(self) -> int:
        return self.available_quantity + self.reserved_quantity

    def can_reserve(self, quantity: int) -> bool:
        return self.available_quantity >= quantity

    def reserve(self, quantity: int) -> bool:
        if not self.can_reserve(quantity):
            return False
        self.available_quantity -= quantity
        self.reserved_quantity += quantity
        self.updated_at = datetime.utcnow()
        return True

    def release_reservation(self, quantity: int) -> bool:
        if self.reserved_quantity < quantity:
            return False
        self.reserved_quantity -= quantity
        self.available_quantity += quantity
        self.updated_at = datetime.utcnow()
        return True