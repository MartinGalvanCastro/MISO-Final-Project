from fastapi import APIRouter, Depends, HTTPException, status

from src.infrastructure.api.dto.inventory_dto import CheckStockRequest, CheckStockResponse, ReserveStockRequest, ReserveStockResponse
from src.infrastructure.api.dependencies import get_check_stock_use_case, get_reserve_stock_use_case
from src.application.use_cases.check_stock import CheckStockUseCase
from src.application.use_cases.reserve_stock import ReserveStockUseCase

router = APIRouter(prefix="/api/v1/inventory", tags=["inventory"])


@router.post(
    "/check",
    response_model=CheckStockResponse,
    summary="Check stock availability",
    description="""
    Checks the available stock for the specified products.

    **Process:**
    1. Validates product IDs exist in inventory
    2. Returns current available quantities for each product
    3. Products not found will have quantity 0

    **Use Cases:**
    - Pre-order validation by order service
    - Real-time stock display in frontend
    - Inventory reporting and analytics

    **Note:** This returns available stock only (not reserved quantities).
    """,
    responses={
        200: {
            "description": "Stock levels retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "stock": {
                            "prod-123": 50,
                            "prod-456": 25,
                            "prod-789": 0
                        }
                    }
                }
            }
        },
        400: {
            "description": "Invalid request - empty product list",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Product IDs list cannot be empty"
                    }
                }
            }
        },
        422: {
            "description": "Invalid request format",
            "content": {
                "application/json": {
                    "example": {
                        "detail": [
                            {
                                "loc": ["body", "product_ids"],
                                "msg": "ensure this value has at least 1 items",
                                "type": "value_error"
                            }
                        ]
                    }
                }
            }
        }
    }
)
async def check_stock(
    request: CheckStockRequest,
    use_case: CheckStockUseCase = Depends(get_check_stock_use_case)
):
    """Check stock availability for products"""

    # Execute use case - exceptions will be handled by global exception handlers
    stock = await use_case.execute(request.product_ids)
    return CheckStockResponse(stock=stock)


@router.post(
    "/reserve",
    response_model=ReserveStockResponse,
    summary="Reserve stock for order",
    description="""
    Reserves stock for the specified products and quantities.

    **Process:**
    1. Validates all products exist and have sufficient available stock
    2. Atomically reserves all requested quantities
    3. Updates available/reserved quantities in inventory
    4. Returns success/failure status

    **Business Rules:**
    - All items must be available in requested quantities
    - Reservation is atomic - either all items are reserved or none are
    - Reserved stock is held for a limited time (configurable TTL)
    - Failed reservations do not partially reserve any items

    **Use Cases:**
    - Order processing workflow
    - Shopping cart reservation
    - Pre-order stock allocation

    **Important:** This operation is atomic and transactional.
    """,
    responses={
        200: {
            "description": "Stock reservation processed",
            "content": {
                "application/json": {
                    "examples": {
                        "success": {
                            "summary": "Successful reservation",
                            "value": {
                                "reserved": True
                            }
                        },
                        "insufficient_stock": {
                            "summary": "Insufficient stock",
                            "value": {
                                "reserved": False
                            }
                        }
                    }
                }
            }
        },
        400: {
            "description": "Invalid request - empty items or invalid quantities",
            "content": {
                "application/json": {
                    "examples": {
                        "empty_items": {
                            "summary": "No items to reserve",
                            "value": {
                                "detail": "Items list cannot be empty"
                            }
                        },
                        "invalid_quantity": {
                            "summary": "Invalid quantity",
                            "value": {
                                "detail": "All quantities must be positive"
                            }
                        }
                    }
                }
            }
        },
        404: {
            "description": "One or more products not found",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Product 'prod-999' not found in inventory"
                    }
                }
            }
        },
        422: {
            "description": "Invalid request format",
            "content": {
                "application/json": {
                    "example": {
                        "detail": [
                            {
                                "loc": ["body", "items"],
                                "msg": "field required",
                                "type": "value_error.missing"
                            }
                        ]
                    }
                }
            }
        }
    }
)
async def reserve_stock(
    request: ReserveStockRequest,
    use_case: ReserveStockUseCase = Depends(get_reserve_stock_use_case)
):
    """Reserve stock for order items"""

    # Execute use case - exceptions will be handled by global exception handlers
    reserved = await use_case.execute(request.items)
    return ReserveStockResponse(reserved=reserved)


