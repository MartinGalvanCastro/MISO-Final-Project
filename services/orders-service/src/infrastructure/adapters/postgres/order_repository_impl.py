from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.domain.models.order import Order, OrderItem, OrderStatus
from src.domain.repositories.order_repository import OrderRepository

from .models import OrderModel


class PostgresOrderRepository(OrderRepository):
    
    def __init__(self, session: AsyncSession):
        self.session = session
    
    async def save(self, order: Order) -> Order:
        db_order = await self.session.get(OrderModel, order.id)
        
        if not db_order:
            db_order = OrderModel()
        
        db_order.id = order.id
        db_order.order_number = order.order_number
        db_order.client_id = order.client_id
        db_order.items = [
            {
                "product_id": item.product_id,
                "quantity": item.quantity,
                "price": item.price
            }
            for item in order.items
        ]
        db_order.total = order.total
        db_order.status = order.status.value
        db_order.created_at = order.created_at
        db_order.delivery_id = order.delivery_id
        
        self.session.add(db_order)
        await self.session.commit()
        await self.session.refresh(db_order)
        
        return self._to_domain(db_order)
    
    async def find_by_id(self, order_id: str) -> Order | None:
        result = await self.session.execute(
            select(OrderModel).where(OrderModel.id == order_id)
        )
        db_order = result.scalar_one_or_none()
        
        return self._to_domain(db_order) if db_order else None
    
    async def find_all(self, limit: int = 100, offset: int = 0) -> list[Order]:
        result = await self.session.execute(
            select(OrderModel)
            .order_by(OrderModel.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        db_orders = result.scalars().all()
        
        return [self._to_domain(db_order) for db_order in db_orders]
    
    def _to_domain(self, db_order: OrderModel) -> Order:
        items = [
            OrderItem(
                product_id=item["product_id"],
                quantity=item["quantity"],
                price=item["price"]
            )
            for item in db_order.items
        ]
        
        order = Order(
            client_id=db_order.client_id,
            items=items
        )
        order.id = db_order.id
        order.order_number = db_order.order_number
        order.status = OrderStatus(db_order.status)
        order.created_at = db_order.created_at
        order.delivery_id = db_order.delivery_id
        
        return order