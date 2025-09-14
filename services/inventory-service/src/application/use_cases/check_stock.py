import logging
from typing import Dict, List
from src.domain.repositories.inventory_repository import InventoryRepository
from src.domain.exceptions import ValidationException, DatabaseException

logger = logging.getLogger(__name__)


class CheckStockUseCase:

    def __init__(self, inventory_repository: InventoryRepository):
        self.inventory_repository = inventory_repository

    async def execute(self, product_ids: List[str]) -> Dict[str, int]:
        """
        Check available stock for multiple products
        Returns dict with product_id -> available_quantity
        """
        # Validate input
        if not product_ids:
            raise ValidationException("Product IDs list cannot be empty")

        if len(product_ids) > 100:  # Reasonable limit
            raise ValidationException("Too many product IDs requested. Maximum 100 allowed")

        for product_id in product_ids:
            if not product_id or not product_id.strip():
                raise ValidationException("Product ID cannot be empty or whitespace")

        logger.info(f"Checking stock for {len(product_ids)} products")

        try:
            items = await self.inventory_repository.find_by_product_ids(product_ids)

            result = {}
            for product_id in product_ids:
                if product_id in items:
                    result[product_id] = items[product_id].available_quantity
                else:
                    result[product_id] = 0
                    logger.warning(f"Product {product_id} not found in inventory")

            logger.info(f"Successfully checked stock for {len(product_ids)} products")
            return result

        except Exception as e:
            logger.error(f"Error checking stock: {str(e)}")
            raise DatabaseException(f"Failed to check stock: {str(e)}")