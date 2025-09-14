from functools import lru_cache
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.application.use_cases.check_stock import CheckStockUseCase
from src.application.use_cases.reserve_stock import ReserveStockUseCase
from src.infrastructure.adapters.postgres.inventory_repository_impl import PostgresInventoryRepository
from src.infrastructure.adapters.postgres.session import get_db_session


def get_repository(session: AsyncSession) -> PostgresInventoryRepository:
    """Factory for repository - not cached as session is per request"""
    return PostgresInventoryRepository(session)


@lru_cache()
def get_check_stock_use_case_factory():
    """Singleton factory for CheckStockUseCase factory function"""
    def create_use_case(session: AsyncSession = Depends(get_db_session)) -> CheckStockUseCase:
        repository = get_repository(session)
        return CheckStockUseCase(inventory_repository=repository)
    return create_use_case


@lru_cache()
def get_reserve_stock_use_case_factory():
    """Singleton factory for ReserveStockUseCase factory function"""
    def create_use_case(session: AsyncSession = Depends(get_db_session)) -> ReserveStockUseCase:
        repository = get_repository(session)
        return ReserveStockUseCase(inventory_repository=repository)
    return create_use_case


def get_check_stock_use_case(
    session: AsyncSession = Depends(get_db_session)
) -> CheckStockUseCase:
    repository = get_repository(session)
    return CheckStockUseCase(inventory_repository=repository)


def get_reserve_stock_use_case(
    session: AsyncSession = Depends(get_db_session)
) -> ReserveStockUseCase:
    repository = get_repository(session)
    return ReserveStockUseCase(inventory_repository=repository)