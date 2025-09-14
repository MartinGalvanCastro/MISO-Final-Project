import logging
from datetime import datetime, timedelta

from src.application.ports.event_publisher import EventPublisher
from src.application.ports.inventory_service import InventoryService
from src.domain.models.order import Order
from src.domain.repositories.order_repository import OrderRepository
from src.domain.exceptions import (
    BusinessRuleViolationException,
    InsufficientStockException,
    StockReservationException,
    ExternalServiceException
)

logger = logging.getLogger(__name__)


class CreateOrderUseCase:
    
    def __init__(
        self,
        order_repository: OrderRepository,
        inventory_service: InventoryService,
        event_publisher: EventPublisher
    ):
        self.order_repository = order_repository
        self.inventory_service = inventory_service
        self.event_publisher = event_publisher
    
    async def execute(self, order: Order) -> Order:
        """
        Create a new order with stock validation
        """
        
        # 1. Validate business rules
        is_valid, error_message = order.validate_business_rules()
        if not is_valid:
            order.reject()
            await self.order_repository.save(order)
            logger.warning(f"Order {order.id} rejected: {error_message}")
            raise BusinessRuleViolationException(error_message)
        
        # 2. Save initial order
        order = await self.order_repository.save(order)
        logger.info(f"Order {order.id} created with PENDING status")
        
        try:
            # 3. Check inventory
            product_ids = [item.product_id for item in order.items]
            try:
                stock_availability = await self.inventory_service.check_stock(product_ids)
            except Exception as e:
                logger.error(f"Failed to check stock for order {order.id}: {str(e)}")
                raise ExternalServiceException(f"Inventory service unavailable: {str(e)}")

            # Verify stock for each item
            for item in order.items:
                available = stock_availability.get(item.product_id, 0)
                if available < item.quantity:
                    order.reject()
                    await self.order_repository.save(order)
                    error_msg = f"Insufficient stock for product {item.product_id}. Available: {available}, Required: {item.quantity}"
                    logger.warning(f"Order {order.id} rejected: {error_msg}")
                    raise InsufficientStockException(error_msg)
            
            # 4. Validate order
            order.validate()
            await self.order_repository.save(order)
            logger.info(f"Order {order.id} validated")
            
            # 5. Reserve stock
            items_to_reserve = {
                item.product_id: item.quantity for item in order.items
            }

            try:
                stock_reserved = await self.inventory_service.reserve_stock(items_to_reserve)
            except Exception as e:
                logger.error(f"Failed to reserve stock for order {order.id}: {str(e)}")
                raise ExternalServiceException(f"Stock reservation service unavailable: {str(e)}")

            if not stock_reserved:
                order.reject()
                await self.order_repository.save(order)
                logger.error(f"Order {order.id} failed to reserve stock")
                raise StockReservationException("Failed to reserve stock - items may have been sold to another customer")
            
            # 6. Confirm order and set delivery date
            order.confirm()
            order.delivery_id = f"delivery-{order.id[:8]}"
            await self.order_repository.save(order)
            
            # 7. Publish event
            await self._publish_order_created_event(order)
            
            logger.info(f"Order {order.id} created successfully")
            return order
            
        except Exception as e:
            logger.error(f"Error processing order {order.id}: {str(e)}")
            if order.status.value == "pending":
                order.reject()
                await self.order_repository.save(order)
            raise
    
    async def _publish_order_created_event(self, order: Order) -> None:
        """Publish order created event"""
        event_payload = {
            "order_id": order.id,
            "order_number": order.order_number,
            "client_id": order.client_id,
            "vendor_id": order.vendor_id,
            "total": order.total,
            "items": [
                {
                    "product_id": item.product_id,
                    "quantity": item.quantity,
                    "price": item.price
                }
                for item in order.items
            ],
            "delivery_id": order.delivery_id,
            "created_at": order.created_at.isoformat()
        }
        
        await self.event_publisher.publish("OrderCreated", event_payload)