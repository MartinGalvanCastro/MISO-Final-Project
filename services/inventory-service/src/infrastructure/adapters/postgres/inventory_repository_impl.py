from typing import Optional, List, Dict
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from src.domain.models.inventory import InventoryItem
from src.domain.repositories.inventory_repository import InventoryRepository
from src.infrastructure.adapters.postgres.models import InventoryModel


class PostgresInventoryRepository(InventoryRepository):

    def __init__(self, session: AsyncSession):
        self.session = session

    async def find_by_product_id(self, product_id: str) -> Optional[InventoryItem]:
        result = await self.session.execute(
            select(InventoryModel).where(InventoryModel.product_id == product_id)
        )
        db_item = result.scalar_one_or_none()

        return self._to_domain(db_item) if db_item else None

    async def find_by_product_ids(self, product_ids: List[str]) -> Dict[str, InventoryItem]:
        result = await self.session.execute(
            select(InventoryModel).where(InventoryModel.product_id.in_(product_ids))
        )
        db_items = result.scalars().all()

        return {
            item.product_id: self._to_domain(item)
            for item in db_items
        }

    async def save(self, item: InventoryItem) -> InventoryItem:
        db_item = await self.session.get(InventoryModel, item.product_id)

        if not db_item:
            db_item = InventoryModel()
            db_item.product_id = item.product_id

        db_item.available_quantity = item.available_quantity
        db_item.reserved_quantity = item.reserved_quantity
        db_item.updated_at = item.updated_at or datetime.utcnow()

        self.session.add(db_item)
        await self.session.commit()
        await self.session.refresh(db_item)

        return self._to_domain(db_item)

    async def save_all(self, items: List[InventoryItem]) -> List[InventoryItem]:
        saved_items = []
        for item in items:
            saved_item = await self.save(item)
            saved_items.append(saved_item)
        return saved_items

    def _to_domain(self, db_item: InventoryModel) -> InventoryItem:
        return InventoryItem(
            product_id=db_item.product_id,
            available_quantity=db_item.available_quantity,
            reserved_quantity=db_item.reserved_quantity,
            updated_at=db_item.updated_at
        )