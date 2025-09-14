"""Domain exceptions for the orders service"""


class OrderDomainException(Exception):
    """Base exception for order domain errors"""
    pass


class BusinessRuleViolationException(OrderDomainException):
    """Raised when business rules are violated"""
    pass


class InsufficientStockException(OrderDomainException):
    """Raised when there's insufficient stock for an order"""
    pass


class StockReservationException(OrderDomainException):
    """Raised when stock reservation fails"""
    pass


class OrderNotFoundException(OrderDomainException):
    """Raised when an order is not found"""
    pass


class OrderValidationException(OrderDomainException):
    """Raised when order validation fails"""
    pass


class ExternalServiceException(OrderDomainException):
    """Raised when external service calls fail"""
    pass