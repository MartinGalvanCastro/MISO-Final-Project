import logging
from typing import Dict
from src.domain.repositories.inventory_repository import InventoryRepository
from src.domain.exceptions import (
    ProductNotFoundException,
    InsufficientStockException,
    StockReservationException,
    InvalidQuantityException,
    ValidationException,
    DatabaseException
)

logger = logging.getLogger(__name__)


class ReserveStockUseCase:

    def __init__(self, inventory_repository: InventoryRepository):
        self.inventory_repository = inventory_repository

    async def execute(self, items: Dict[str, int]) -> bool:
        """
        Reserve stock for multiple items
        Args: Dict with product_id -> quantity to reserve
        Returns: True if all reservations successful
        Raises: Various exceptions for different error conditions
        """
        # Validate input
        if not items:
            raise ValidationException("Items dictionary cannot be empty")

        if len(items) > 50:  # Reasonable limit for reservations
            raise ValidationException("Too many items to reserve. Maximum 50 allowed")

        # Validate each item
        for product_id, quantity in items.items():
            if not product_id or not product_id.strip():
                raise ValidationException("Product ID cannot be empty or whitespace")

            if not isinstance(quantity, int) or quantity <= 0:
                raise InvalidQuantityException(f"Invalid quantity {quantity} for product {product_id}. Must be a positive integer")

            if quantity > 10000:  # Reasonable max quantity
                raise InvalidQuantityException(f"Quantity {quantity} too large for product {product_id}. Maximum 10000 allowed")

        logger.info(f"Attempting to reserve stock for {len(items)} products")

        try:
            product_ids = list(items.keys())
            inventory_items = await self.inventory_repository.find_by_product_ids(product_ids)

            # Check if all items exist and can be reserved
            missing_products = []
            insufficient_stock = []

            for product_id, quantity in items.items():
                if product_id not in inventory_items:
                    missing_products.append(product_id)
                    continue

                inventory_item = inventory_items[product_id]
                if not inventory_item.can_reserve(quantity):
                    insufficient_stock.append({
                        "product_id": product_id,
                        "requested": quantity,
                        "available": inventory_item.available_quantity
                    })

            # Raise specific exceptions for missing products
            if missing_products:
                error_msg = f"Products not found: {', '.join(missing_products)}"
                logger.error(error_msg)
                raise ProductNotFoundException(error_msg)

            # Raise specific exceptions for insufficient stock
            if insufficient_stock:
                error_details = []
                for item in insufficient_stock:
                    error_details.append(
                        f"{item['product_id']} (requested: {item['requested']}, available: {item['available']})"
                    )
                error_msg = f"Insufficient stock for products: {', '.join(error_details)}"
                logger.error(error_msg)
                raise InsufficientStockException(error_msg)

            # Reserve all items
            items_to_save = []
            for product_id, quantity in items.items():
                inventory_item = inventory_items[product_id]
                success = inventory_item.reserve(quantity)
                if not success:
                    # This shouldn't happen after our checks, but just in case
                    raise StockReservationException(f"Failed to reserve {quantity} units of product {product_id}")
                items_to_save.append(inventory_item)

            # Save all reservations
            try:
                await self.inventory_repository.save_all(items_to_save)
                logger.info(f"Successfully reserved stock for {len(items)} products")
                return True

            except Exception as e:
                logger.error(f"Failed to save stock reservations: {str(e)}")
                raise StockReservationException(f"Failed to save reservations: {str(e)}")

        except (ProductNotFoundException, InsufficientStockException, StockReservationException):
            # Re-raise domain exceptions
            raise
        except Exception as e:
            logger.error(f"Unexpected error during stock reservation: {str(e)}")
            raise DatabaseException(f"Failed to reserve stock: {str(e)}")