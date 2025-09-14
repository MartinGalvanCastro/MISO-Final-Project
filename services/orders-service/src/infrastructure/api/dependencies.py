from functools import lru_cache
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.application.use_cases.create_order import CreateOrderUseCase
from src.application.use_cases.get_order import GetOrderUseCase
from src.infrastructure.adapters.http.inventory_service_impl import HTTPInventoryService
from src.infrastructure.adapters.messaging.sqs_event_publisher import SQSEventPublisher
from src.infrastructure.adapters.postgres.order_repository_impl import (
    PostgresOrderRepository,
)
from src.infrastructure.adapters.postgres.session import get_db_session
from src.infrastructure.config.settings import settings


@lru_cache()
def get_inventory_service() -> HTTPInventoryService:
    """Singleton factory for HTTPInventoryService"""
    return HTTPInventoryService()


@lru_cache()
def get_event_publisher():
    """Singleton factory for event publisher"""
    if settings.ENVIRONMENT == "local":
        from src.infrastructure.adapters.messaging.mock_event_publisher import (
            MockEventPublisher,
        )
        return MockEventPublisher()
    else:
        return SQSEventPublisher()


def get_create_order_use_case(
    session: AsyncSession = Depends(get_db_session),
    inventory_service: HTTPInventoryService = Depends(get_inventory_service),
    event_publisher = Depends(get_event_publisher)
) -> CreateOrderUseCase:
    """Dependency injection for CreateOrderUseCase"""

    order_repository = PostgresOrderRepository(session)

    return CreateOrderUseCase(
        order_repository=order_repository,
        inventory_service=inventory_service,
        event_publisher=event_publisher
    )


def get_order_use_case(
    session: AsyncSession = Depends(get_db_session)
) -> GetOrderUseCase:
    """Dependency injection for GetOrderUseCase"""
    
    order_repository = PostgresOrderRepository(session)
    return GetOrderUseCase(order_repository=order_repository)