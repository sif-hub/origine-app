"""family calendar events

Revision ID: e4f7c1a8b2d6
Revises: d8b5a2c9f1e3
Create Date: 2026-09-18 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e4f7c1a8b2d6'
down_revision: Union[str, Sequence[str], None] = 'd8b5a2c9f1e3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

TYPES_EVENEMENT = (
    'ANNIVERSAIRE', 'ANNIVERSAIRE_DECES', 'MARIAGE', 'NAISSANCE',
    'BAPTEME', 'CEREMONIE', 'REUNION', 'AUTRE',
)


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table('family_events',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('created_by', sa.BigInteger(), nullable=False),
        sa.Column('nom', sa.String(length=150), nullable=False),
        sa.Column('type_evenement', sa.Enum(*TYPES_EVENEMENT), nullable=False, server_default='AUTRE'),
        sa.Column('date_evenement', sa.Date(), nullable=False),
        sa.Column('heure', sa.Time(), nullable=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('personne_concernee', sa.String(length=150), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('family_events')
