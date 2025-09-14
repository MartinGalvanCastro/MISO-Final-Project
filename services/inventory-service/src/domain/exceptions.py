"""Domain exceptions for the inventory service"""


class InventoryDomainException(Exception):
    """Base exception for inventory domain errors"""
    pass


class ProductNotFoundException(InventoryDomainException):
    """Raised when a product is not found in inventory"""
    pass


class InsufficientStockException(InventoryDomainException):
    """Raised when there's insufficient stock for a reservation"""
    pass


class StockReservationException(InventoryDomainException):
    """Raised when stock reservation fails"""
    pass


class InvalidQuantityException(InventoryDomainException):
    """Raised when an invalid quantity is provided"""
    pass


class DatabaseException(InventoryDomainException):
    """Raised when database operations fail"""
    pass


class ValidationException(InventoryDomainException):
    """Raised when validation fails"""
    pass