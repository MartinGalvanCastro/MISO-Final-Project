from pydantic import BaseModel, Field
from typing import List, Dict


class CheckStockRequest(BaseModel):
    """Request model for checking stock availability"""
    product_ids: List[str] = Field(..., description="List of product IDs to check stock for", min_items=1)

    class Config:
        json_schema_extra = {
            "example": {
                "product_ids": ["prod-123", "prod-456", "prod-789"]
            }
        }


class CheckStockResponse(BaseModel):
    """Response model for stock availability check"""
    stock: Dict[str, int] = Field(..., description="Map of product IDs to available stock quantities")

    class Config:
        json_schema_extra = {
            "example": {
                "stock": {
                    "prod-123": 50,
                    "prod-456": 25,
                    "prod-789": 0
                }
            }
        }


class ReserveStockRequest(BaseModel):
    """Request model for reserving stock"""
    items: Dict[str, int] = Field(..., description="Map of product IDs to quantities to reserve")

    class Config:
        json_schema_extra = {
            "example": {
                "items": {
                    "prod-123": 2,
                    "prod-456": 1
                }
            }
        }


class ReserveStockResponse(BaseModel):
    """Response model for stock reservation"""
    reserved: bool = Field(..., description="Whether the stock reservation was successful")

    class Config:
        json_schema_extra = {
            "example": {
                "reserved": True
            }
        }