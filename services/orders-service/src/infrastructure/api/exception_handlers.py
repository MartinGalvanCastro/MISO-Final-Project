"""Global exception handlers for the orders service"""

import logging
from fastapi import Request, status
from fastapi.responses import JSONResponse

from src.domain.exceptions import (
    BusinessRuleViolationException,
    InsufficientStockException,
    StockReservationException,
    OrderNotFoundException,
    OrderValidationException,
    ExternalServiceException
)

logger = logging.getLogger(__name__)


async def business_rule_violation_handler(
    request: Request, exc: BusinessRuleViolationException
) -> JSONResponse:
    """Handle business rule violation exceptions"""
    logger.warning(f"Business rule violation: {str(exc)}")
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={
            "error": "Business Rule Violation",
            "detail": str(exc),
            "type": "business_rule_violation"
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


async def order_not_found_handler(
    request: Request, exc: OrderNotFoundException
) -> JSONResponse:
    """Handle order not found exceptions"""
    logger.info(f"Order not found: {str(exc)}")
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={
            "error": "Order Not Found",
            "detail": str(exc),
            "type": "order_not_found"
        }
    )


async def external_service_handler(
    request: Request, exc: ExternalServiceException
) -> JSONResponse:
    """Handle external service exceptions"""
    logger.error(f"External service error: {str(exc)}")
    return JSONResponse(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        content={
            "error": "External Service Unavailable",
            "detail": "A required external service is temporarily unavailable. Please try again later.",
            "type": "external_service_error"
        }
    )


async def validation_exception_handler(
    request: Request, exc: OrderValidationException
) -> JSONResponse:
    """Handle order validation exceptions"""
    logger.warning(f"Order validation error: {str(exc)}")
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
    BusinessRuleViolationException: business_rule_violation_handler,
    InsufficientStockException: insufficient_stock_handler,
    StockReservationException: stock_reservation_handler,
    OrderNotFoundException: order_not_found_handler,
    OrderValidationException: validation_exception_handler,
    ExternalServiceException: external_service_handler,
    Exception: general_exception_handler,
}