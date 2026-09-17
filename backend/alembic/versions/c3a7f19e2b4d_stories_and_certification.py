"""stories feed, comments, likes, reports and author certification

Revision ID: c3a7f19e2b4d
Revises: 8e21c4f6a9d1
Create Date: 2026-09-17 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c3a7f19e2b4d'
down_revision: Union[str, Sequence[str], None] = '8e21c4f6a9d1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

CATEGORIES = (
    'TRADITIONS_COUTUMES', 'HISTOIRE_PEUPLES', 'PERSONNALITES_FIGURES',
    'LIEUX_PATRIMOINE', 'RITES_CEREMONIES', 'CONTES_LEGENDES',
    'LANGUES_EXPRESSIONS', 'ART_MUSIQUE_DANSE', 'VIE_QUOTIDIENNE', 'AUTRE',
)


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('users', sa.Column(
        'statut_auteur', sa.Enum('UTILISATEUR', 'PROFESSIONNEL'), nullable=False,
        server_default='UTILISATEUR',
    ))
    op.add_column('users', sa.Column('certifie', sa.Boolean(), nullable=False, server_default=sa.false()))

    op.create_table('stories',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('author_id', sa.BigInteger(), nullable=False),
        sa.Column('titre', sa.String(length=200), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('date_histoire', sa.Date(), nullable=True),
        sa.Column('region', sa.String(length=100), nullable=True),
        sa.Column('village', sa.String(length=150), nullable=True),
        sa.Column('categorie', sa.Enum(*CATEGORIES), nullable=False),
        sa.Column('mots_cles', sa.String(length=255), nullable=True),
        sa.Column('source', sa.String(length=255), nullable=True),
        sa.Column('autoriser_tts', sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['author_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_table('story_media',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('story_id', sa.BigInteger(), nullable=False),
        sa.Column('type', sa.Enum('PHOTO', 'VIDEO', 'AUDIO'), nullable=False),
        sa.Column('nom_fichier', sa.String(length=255), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['story_id'], ['stories.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_table('story_likes',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('story_id', sa.BigInteger(), nullable=False),
        sa.Column('user_id', sa.BigInteger(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['story_id'], ['stories.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('story_id', 'user_id'),
    )

    op.create_table('story_comments',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('story_id', sa.BigInteger(), nullable=False),
        sa.Column('user_id', sa.BigInteger(), nullable=False),
        sa.Column('contenu', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['story_id'], ['stories.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_table('story_reports',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('story_id', sa.BigInteger(), nullable=False),
        sa.Column('user_id', sa.BigInteger(), nullable=False),
        sa.Column('raison', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['story_id'], ['stories.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_table('certification_requests',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('user_id', sa.BigInteger(), nullable=False),
        sa.Column('type_professionnel', sa.Enum('GRIOT', 'GENEALOGISTE', 'HISTORIEN', 'AUTRE'), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('document_fichier', sa.String(length=255), nullable=False),
        sa.Column('statut', sa.Enum('EN_ATTENTE', 'APPROUVEE', 'REJETEE'), nullable=False,
                   server_default='EN_ATTENTE'),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('certification_requests')
    op.drop_table('story_reports')
    op.drop_table('story_comments')
    op.drop_table('story_likes')
    op.drop_table('story_media')
    op.drop_table('stories')
    op.drop_column('users', 'certifie')
    op.drop_column('users', 'statut_auteur')
