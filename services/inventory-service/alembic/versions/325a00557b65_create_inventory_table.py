"""create inventory table

Revision ID: 325a00557b65
Revises: 
Create Date: 2025-09-14 04:55:27.568912

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '325a00557b65'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create inventory table
    op.create_table('inventory',
        sa.Column('product_id', sa.String(), nullable=False),
        sa.Column('available_quantity', sa.Integer(), nullable=False, default=0),
        sa.Column('reserved_quantity', sa.Integer(), nullable=False, default=0),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.PrimaryKeyConstraint('product_id')
    )
    op.create_index('ix_inventory_product_id', 'inventory', ['product_id'], unique=False)


def downgrade() -> None:
    op.drop_index('ix_inventory_product_id', table_name='inventory')
    op.drop_table('inventory')