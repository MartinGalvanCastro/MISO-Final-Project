from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List

from src.application.use_cases.create_order import CreateOrderUseCase
from src.application.use_cases.get_order import GetOrderUseCase
from src.domain.models.order import Order, OrderItem
from src.infrastructure.api.dependencies import (
    get_create_order_use_case,
    get_order_use_case,
)
from src.infrastructure.api.dto.order_dto import CreateOrderRequest, OrderResponse, OrderItemResponse

router = APIRouter(prefix="/api/v1/orders", tags=["orders"])


@router.post(
    "/",
    response_model=OrderResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new order",
    description="""
    Creates a new order with the specified items and validates business rules.

    **Business Rules:**
    - Order must have at least one item
    - Minimum order total: $10.00
    - Maximum items per order: 100
    - All item quantities must be positive
    - All item prices must be non-negative

    **Process:**
    1. Validates order against business rules
    2. Checks inventory availability
    3. Reserves stock if available
    4. Creates confirmed order with delivery date

    **Possible Statuses:**
    - `pending`: Order created but not yet validated
    - `validated`: Order passed validation
    - `created`: Order successfully created and stock reserved
    - `rejected`: Order rejected due to validation or stock issues
    """,
    responses={
        201: {
            "description": "Order created successfully",
            "content": {
                "application/json": {
                    "example": {
                        "id": "550e8400-e29b-41d4-a716-446655440000",
                        "order_number": "ORD-A1B2C3D4",
                        "client_id": "client-456",
                        "vendor_id": "vendor-789",
                        "items": [
                            {
                                "product_id": "prod-123",
                                "quantity": 2,
                                "price": 29.99
                            }
                        ],
                        "total": 59.98,
                        "status": "created",
                        "created_at": "2023-12-01T10:00:00Z",
                        "delivery_id": "delivery-123"
                    }
                }
            }
        },
        400: {
            "description": "Invalid order data or business rule violation",
            "content": {
                "application/json": {
                    "examples": {
                        "validation_error": {
                            "summary": "Business rule violation",
                            "value": {
                                "detail": "Order minimum is $10"
                            }
                        },
                        "empty_items": {
                            "summary": "No items provided",
                            "value": {
                                "detail": "Order must have at least one item"
                            }
                        }
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
                                "loc": ["body", "items", 0, "quantity"],
                                "msg": "ensure this value is greater than 0",
                                "type": "value_error"
                            }
                        ]
                    }
                }
            }
        },
        503: {
            "description": "Service unavailable (inventory service down)",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Inventory service unavailable"
                    }
                }
            }
        }
    }
)
async def create_order(
    request: CreateOrderRequest,
    use_case: CreateOrderUseCase = Depends(get_create_order_use_case)
):
    """Create a new order"""
    
    # Map DTO to domain model
    order_items = [
        OrderItem(
            product_id=item.product_id,
            quantity=item.quantity,
            price=item.price
        )
        for item in request.items
    ]
    
    order = Order(
        client_id=request.client_id,
        vendor_id=request.vendor_id,
        items=order_items
    )
    
    # Execute use case - exceptions will be handled by global exception handlers
    result = await use_case.execute(order)

    # Map domain model to response DTO
    return OrderResponse(
        id=result.id,
        order_number=result.order_number,
        client_id=result.client_id,
        vendor_id=result.vendor_id,
        items=[
            OrderItemResponse(
                product_id=item.product_id,
                quantity=item.quantity,
                price=item.price
            )
            for item in result.items
        ],
        total=result.total,
        status=result.status.value,
        created_at=result.created_at,
        delivery_id=result.delivery_id
    )


@router.get(
    "/{order_id}",
    response_model=OrderResponse,
    summary="Get order by ID",
    description="""
    Retrieves a specific order by its unique identifier.

    **Path Parameters:**
    - `order_id`: The unique UUID of the order to retrieve

    **Returns:**
    Complete order information including items, status, and timestamps.
    """,
    responses={
        200: {
            "description": "Order found successfully",
            "content": {
                "application/json": {
                    "example": {
                        "id": "550e8400-e29b-41d4-a716-446655440000",
                        "order_number": "ORD-A1B2C3D4",
                        "client_id": "client-456",
                        "vendor_id": "vendor-789",
                        "items": [
                            {
                                "product_id": "prod-123",
                                "quantity": 2,
                                "price": 29.99
                            }
                        ],
                        "total": 59.98,
                        "status": "created",
                        "created_at": "2023-12-01T10:00:00Z",
                        "delivery_id": "delivery-123"
                    }
                }
            }
        },
        404: {
            "description": "Order not found",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Order with id '550e8400-e29b-41d4-a716-446655440000' not found"
                    }
                }
            }
        },
        422: {
            "description": "Invalid order ID format",
            "content": {
                "application/json": {
                    "example": {
                        "detail": [
                            {
                                "loc": ["path", "order_id"],
                                "msg": "Invalid UUID format",
                                "type": "value_error"
                            }
                        ]
                    }
                }
            }
        }
    }
)
async def get_order(
    order_id: str,
    use_case: GetOrderUseCase = Depends(get_order_use_case)
):
    """Get order by ID"""

    # Execute use case - exceptions will be handled by global exception handlers
    order = await use_case.by_id(order_id)

    return OrderResponse(
        id=order.id,
        order_number=order.order_number,
        client_id=order.client_id,
        vendor_id=order.vendor_id,
        items=[
            OrderItemResponse(
                product_id=item.product_id,
                quantity=item.quantity,
                price=item.price
            )
            for item in order.items
        ],
        total=order.total,
        status=order.status.value,
        created_at=order.created_at,
        delivery_id=order.delivery_id
    )


@router.get(
    "/",
    response_model=List[OrderResponse],
    summary="Get orders with pagination",
    description="""
    Retrieves a paginated list of orders.

    **Query Parameters:**
    - `limit`: Maximum number of orders to return (default: 100, max: 1000)
    - `offset`: Number of orders to skip for pagination (default: 0)

    **Returns:**
    List of orders sorted by creation date (newest first).

    **Example Usage:**
    - Get first 50 orders: `GET /api/v1/orders?limit=50`
    - Get next 50 orders: `GET /api/v1/orders?limit=50&offset=50`
    """,
    responses={
        200: {
            "description": "Orders retrieved successfully",
            "content": {
                "application/json": {
                    "example": [
                        {
                            "id": "550e8400-e29b-41d4-a716-446655440000",
                            "order_number": "ORD-A1B2C3D4",
                            "client_id": "client-456",
                            "vendor_id": "vendor-789",
                            "items": [
                                {
                                    "product_id": "prod-123",
                                    "quantity": 2,
                                    "price": 29.99
                                }
                            ],
                            "total": 59.98,
                            "status": "created",
                            "created_at": "2023-12-01T10:00:00Z",
                            "delivery_id": "delivery-123"
                        }
                    ]
                }
            }
        },
        422: {
            "description": "Invalid pagination parameters",
            "content": {
                "application/json": {
                    "example": {
                        "detail": [
                            {
                                "loc": ["query", "limit"],
                                "msg": "ensure this value is less than or equal to 1000",
                                "type": "value_error"
                            }
                        ]
                    }
                }
            }
        }
    }
)
async def get_orders(
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of orders to return"),
    offset: int = Query(0, ge=0, description="Number of orders to skip"),
    use_case: GetOrderUseCase = Depends(get_order_use_case)
):
    """Get all orders with pagination"""

    # Execute use case - exceptions will be handled by global exception handlers
    orders = await use_case.find_all(limit=limit, offset=offset)
    
    return [
        OrderResponse(
            id=order.id,
            order_number=order.order_number,
            client_id=order.client_id,
            vendor_id=order.vendor_id,
            items=[
                OrderItemResponse(
                    product_id=item.product_id,
                    quantity=item.quantity,
                    price=item.price
                )
                for item in order.items
            ],
            total=order.total,
            status=order.status.value,
            created_at=order.created_at,
            delivery_id=order.delivery_id
        )
        for order in orders
    ]


