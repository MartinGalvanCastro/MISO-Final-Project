"""change delivery_date to delivery_id

Revision ID: 639c8e427233
Revises: d1d448ba60da
Create Date: 2025-09-14 04:58:40.021640

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '639c8e427233'
down_revision: Union[str, None] = 'd1d448ba60da'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add new delivery_id column
    op.add_column('orders', sa.Column('delivery_id', sa.String(), nullable=True))

    # Drop the old delivery_date column
    op.drop_column('orders', 'delivery_date')


def downgrade() -> None:
    # Add back delivery_date column
    op.add_column('orders', sa.Column('delivery_date', sa.DateTime(), nullable=True))

    # Drop delivery_id column
    op.drop_column('orders', 'delivery_id')