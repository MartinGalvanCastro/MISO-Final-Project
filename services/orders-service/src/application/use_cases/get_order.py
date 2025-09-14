import logging
from typing import List, Optional

from src.domain.models.order import Order
from src.domain.repositories.order_repository import OrderRepository
from src.domain.exceptions import OrderNotFoundException

logger = logging.getLogger(__name__)


class GetOrderUseCase:
    
    def __init__(self, order_repository: OrderRepository):
        self.order_repository = order_repository
    
    async def by_id(self, order_id: str) -> Order:
        """Get order by ID"""
        logger.info(f"Fetching order with ID: {order_id}")

        try:
            order = await self.order_repository.find_by_id(order_id)
            if not order:
                logger.warning(f"Order with ID {order_id} not found")
                raise OrderNotFoundException(f"Order {order_id} not found")

            logger.info(f"Successfully retrieved order {order_id}")
            return order
        except OrderNotFoundException:
            raise
        except Exception as e:
            logger.error(f"Error retrieving order {order_id}: {str(e)}")
            raise

    async def find_all(self, limit: int = 100, offset: int = 0) -> List[Order]:
        """Get all orders with pagination"""
        logger.info(f"Fetching orders with limit={limit}, offset={offset}")

        try:
            orders = await self.order_repository.find_all(limit=limit, offset=offset)
            logger.info(f"Successfully retrieved {len(orders)} orders")
            return orders
        except Exception as e:
            logger.error(f"Error retrieving orders: {str(e)}")
            raise