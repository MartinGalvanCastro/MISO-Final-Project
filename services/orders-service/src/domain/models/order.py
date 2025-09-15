import uuid
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum


class OrderStatus(Enum):
    PENDING = "pending"
    VALIDATED = "validated"
    REJECTED = "rejected"
    CREATED = "created"


@dataclass
class OrderItem:
    product_id: str
    quantity: int
    price: float

    def calculate_subtotal(self) -> float:
        return self.quantity * self.price


@dataclass
class Order:
    client_id: str
    items: list[OrderItem]
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    order_number: str = field(default_factory=lambda: str(uuid.uuid4())[:8].upper())
    total: float = field(init=False)
    status: OrderStatus = OrderStatus.PENDING
    created_at: datetime = field(default_factory=datetime.utcnow)
    delivery_id: str | None = None
    
    def __post_init__(self):
        self.total = sum(item.calculate_subtotal() for item in self.items)
    
    def validate(self) -> None:
        if self.status != OrderStatus.PENDING:
            raise ValueError(f"Cannot validate order in {self.status} status")
        self.status = OrderStatus.VALIDATED
    
    def confirm(self) -> None:
        if self.status != OrderStatus.VALIDATED:
            raise ValueError(f"Cannot confirm order in {self.status} status")
        self.status = OrderStatus.CREATED
    
    def reject(self) -> None:
        self.status = OrderStatus.REJECTED

    def validate_business_rules(self) -> tuple[bool, str]:
        """Returns (is_valid, error_message)"""
        if not self.items:
            return False, "Order must have at least one item"

        if self.total < 10.0:
            return False, "Order minimum is $10"

        if len(self.items) > 100:
            return False, "Order cannot exceed 100 items"

        for item in self.items:
            if item.quantity <= 0:
                return False, "Item quantity must be positive"
            if item.price < 0:
                return False, "Item price cannot be negative"

        return True, ""