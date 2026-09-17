"""family groups, membership and messages

Revision ID: d8b5a2c9f1e3
Revises: c3a7f19e2b4d
Create Date: 2026-09-18 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd8b5a2c9f1e3'
down_revision: Union[str, Sequence[str], None] = 'c3a7f19e2b4d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table('family_groups',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('nom', sa.String(length=150), nullable=False),
        sa.Column('created_by', sa.BigInteger(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_table('family_group_members',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('group_id', sa.BigInteger(), nullable=False),
        sa.Column('user_id', sa.BigInteger(), nullable=False),
        sa.Column('joined_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['group_id'], ['family_groups.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('group_id', 'user_id'),
    )

    op.create_table('family_messages',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('group_id', sa.BigInteger(), nullable=False),
        sa.Column('sender_id', sa.BigInteger(), nullable=False),
        sa.Column('contenu', sa.Text(), nullable=True),
        sa.Column('type_message', sa.Enum('TEXT', 'IMAGE'), nullable=False, server_default='TEXT'),
        sa.Column('nom_fichier', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['group_id'], ['family_groups.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['sender_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('family_messages')
    op.drop_table('family_group_members')
    op.drop_table('family_groups')
