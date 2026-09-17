"""person documents, memories and per-member privacy

Revision ID: 8e21c4f6a9d1
Revises: 4872d87fd5b0
Create Date: 2026-09-15 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '8e21c4f6a9d1'
down_revision: Union[str, Sequence[str], None] = '4872d87fd5b0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('persons', sa.Column('lieu_naissance', sa.String(length=200), nullable=True))
    op.add_column('persons', sa.Column('village_origine', sa.String(length=150), nullable=True))
    op.add_column('persons', sa.Column('nationalite', sa.String(length=100), nullable=True,
                                        server_default='Camerounais(e)'))
    op.add_column('persons', sa.Column('profession', sa.String(length=150), nullable=True))
    op.add_column('persons', sa.Column('nom_pere_texte', sa.String(length=200), nullable=True))
    op.add_column('persons', sa.Column('nom_mere_texte', sa.String(length=200), nullable=True))
    op.add_column('persons', sa.Column(
        'visibilite', sa.Enum('PRIVE', 'PARTAGE', 'PUBLIC'), nullable=False, server_default='PRIVE'
    ))
    op.add_column('persons', sa.Column('peut_voir', sa.Boolean(), nullable=False, server_default=sa.true()))
    op.add_column('persons', sa.Column('peut_modifier', sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column('persons', sa.Column('peut_ajouter_documents', sa.Boolean(), nullable=False,
                                        server_default=sa.false()))
    op.add_column('persons', sa.Column('peut_ajouter_souvenirs', sa.Boolean(), nullable=False,
                                        server_default=sa.true()))
    op.add_column('persons', sa.Column('peut_commenter', sa.Boolean(), nullable=False, server_default=sa.true()))

    op.create_table('person_documents',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('person_id', sa.BigInteger(), nullable=False),
        sa.Column('type_document', sa.Enum('ACTE_NAISSANCE', 'ACTE_MARIAGE', 'ACTE_DECES', 'AUTRE'),
                   nullable=False),
        sa.Column('nom_fichier', sa.String(length=255), nullable=False),
        sa.Column('uploaded_by', sa.BigInteger(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['person_id'], ['persons.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['uploaded_by'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_table('person_memories',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('person_id', sa.BigInteger(), nullable=False),
        sa.Column('type', sa.Enum('PHOTO', 'VIDEO', 'AUDIO'), nullable=False),
        sa.Column('nom_fichier', sa.String(length=255), nullable=False),
        sa.Column('uploaded_by', sa.BigInteger(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['person_id'], ['persons.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['uploaded_by'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('person_memories')
    op.drop_table('person_documents')

    op.drop_column('persons', 'peut_commenter')
    op.drop_column('persons', 'peut_ajouter_souvenirs')
    op.drop_column('persons', 'peut_ajouter_documents')
    op.drop_column('persons', 'peut_modifier')
    op.drop_column('persons', 'peut_voir')
    op.drop_column('persons', 'visibilite')
    op.drop_column('persons', 'nom_mere_texte')
    op.drop_column('persons', 'nom_pere_texte')
    op.drop_column('persons', 'profession')
    op.drop_column('persons', 'nationalite')
    op.drop_column('persons', 'village_origine')
    op.drop_column('persons', 'lieu_naissance')
