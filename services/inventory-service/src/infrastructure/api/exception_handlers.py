"""Global exception handlers for the inventory service"""

import logging
from fastapi import Request, status
from fastapi.responses import JSONResponse

from src.domain.exceptions import (
    ProductNotFoundException,
    InsufficientStockException,
    StockReservationException,
    InvalidQuantityException,
    DatabaseException,
    ValidationException
)

logger = logging.getLogger(__name__)


async def product_not_found_handler(
    request: Request, exc: ProductNotFoundException
) -> JSONResponse:
    """Handle product not found exceptions"""
    logger.warning(f"Product not found: {str(exc)}")
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={
            "error": "Product Not Found",
            "detail": str(exc),
            "type": "product_not_found"
        }
    )


async def insufficient_stock_handler(
    request: Request, exc: InsufficientStockException
) -> JSONResponse:
    """Handle insufficient stock exceptions"""
    logger.warning(f"Insufficient stock: {str(exc)}")
    return JSONResponse(
        status_code=status.HTTP_409_CONFLICT,
        content={
            "error": "Insufficient Stock",
            "detail": str(exc),
            "type": "insufficient_stock"
        }
    )


async def stock_reservation_handler(
    request: Request, exc: StockReservationException
) -> JSONResponse:
    """Handle stock reservation exceptions"""
    logger.error(f"Stock reservation failed: {str(exc)}")
    return JSONResponse(
        status_code=status.HTTP_409_CONFLICT,
        content={
            "error": "Stock Reservation Failed",
            "detail": str(exc),
            "type": "stock_reservation_failed"
        }
    )


async def invalid_quantity_handler(
    request: Request, exc: InvalidQuantityException
) -> JSONResponse:
    """Handle invalid quantity exceptions"""
    logger.warning(f"Invalid quantity: {str(exc)}")
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={
            "error": "Invalid Quantity",
            "detail": str(exc),
            "type": "invalid_quantity"
        }
    )


async def database_exception_handler(
    request: Request, exc: DatabaseException
) -> JSONResponse:
    """Handle database exceptions"""
    logger.error(f"Database error: {str(exc)}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "Database Error",
            "detail": "A database error occurred. Please try again later.",
            "type": "database_error"
        }
    )


async def validation_exception_handler(
    request: Request, exc: ValidationException
) -> JSONResponse:
    """Handle validation exceptions"""
    logger.warning(f"Validation error: {str(exc)}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "Validation Error",
            "detail": str(exc),
            "type": "validation_error"
        }
    )


async def general_exception_handler(
    request: Request, exc: Exception
) -> JSONResponse:
    """Handle general exceptions"""
    logger.error(f"Unhandled exception: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "Internal Server Error",
            "detail": "An unexpected error occurred. Please try again later.",
            "type": "internal_error"
        }
    )


# Dictionary mapping exceptions to handlers
EXCEPTION_HANDLERS = {
    ProductNotFoundException: product_not_found_handler,
    InsufficientStockException: insufficient_stock_handler,
    StockReservationException: stock_reservation_handler,
    InvalidQuantityException: invalid_quantity_handler,
    DatabaseException: database_exception_handler,
    ValidationException: validation_exception_handler,
    Exception: general_exception_handler,
}