from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class OrderItemDTO(BaseModel):
    """Individual item within an order"""
    product_id: str = Field(..., description="Unique identifier for the product", example="prod-123")
    quantity: int = Field(gt=0, description="Quantity of the product to order", example=5)
    price: float = Field(gt=0, description="Price per unit of the product", example=29.99)

    class Config:
        json_schema_extra = {
            "example": {
                "product_id": "prod-123",
                "quantity": 5,
                "price": 29.99
            }
        }


class OrderItemResponse(BaseModel):
    """Response model for order items"""
    product_id: str = Field(..., description="Unique identifier for the product")
    quantity: int = Field(..., description="Quantity of the product ordered")
    price: float = Field(..., description="Price per unit of the product")


class CreateOrderRequest(BaseModel):
    """Request model for creating a new order"""
    client_id: str = Field(..., description="Unique identifier for the client", example="client-456")
    items: list[OrderItemDTO] = Field(..., description="List of items to include in the order", min_items=1)

    class Config:
        json_schema_extra = {
            "example": {
                "client_id": "client-456",
                "items": [
                    {
                        "product_id": "prod-123",
                        "quantity": 2,
                        "price": 29.99
                    },
                    {
                        "product_id": "prod-456",
                        "quantity": 1,
                        "price": 15.50
                    }
                ]
            }
        }


class OrderResponse(BaseModel):
    """Response model for order data"""
    id: str = Field(..., description="Unique identifier for the order", example="550e8400-e29b-41d4-a716-446655440000")
    order_number: str = Field(..., description="Human-readable order number", example="ORD-A1B2C3D4")
    client_id: str = Field(..., description="Unique identifier for the client", example="client-456")
    items: list[OrderItemResponse] = Field(..., description="List of items in the order")
    total: float = Field(..., description="Total amount for the order", example=75.48)
    status: str = Field(..., description="Current status of the order", example="pending")
    created_at: datetime = Field(..., description="Timestamp when the order was created")
    delivery_id: Optional[str] = Field(None, description="Delivery identifier (if available)")

    class Config:
        json_schema_extra = {
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "order_number": "ORD-A1B2C3D4",
                "client_id": "client-456",
                "items": [
                    {
                        "product_id": "prod-123",
                        "quantity": 2,
                        "price": 29.99
                    },
                    {
                        "product_id": "prod-456",
                        "quantity": 1,
                        "price": 15.50
                    }
                ],
                "total": 75.48,
                "status": "pending",
                "created_at": "2023-12-01T10:00:00Z",
                "delivery_id": "delivery-123"
            }
        }