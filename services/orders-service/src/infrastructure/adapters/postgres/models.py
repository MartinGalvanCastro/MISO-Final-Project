import enum
from datetime import datetime

from sqlalchemy import JSON, Column, DateTime, Enum, Float, String
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class OrderStatusEnum(enum.Enum):
    PENDING = "pending"
    VALIDATED = "validated"
    REJECTED = "rejected"
    CREATED = "created"


class OrderModel(Base):
    __tablename__ = "orders"
    
    id = Column(String, primary_key=True)
    order_number = Column(String, nullable=False, unique=True, index=True)
    client_id = Column(String, nullable=False, index=True)
    vendor_id = Column(String, nullable=False, index=True)
    items = Column(JSON, nullable=False)
    total = Column(Float, nullable=False)
    status = Column(Enum(OrderStatusEnum), nullable=False, default=OrderStatusEnum.PENDING)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    delivery_id = Column(String, nullable=True)