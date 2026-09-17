# app/models/genealogy.py

from datetime import datetime
from sqlalchemy import (
    Column, BigInteger, String, Enum, Text,
    DateTime, SmallInteger, ForeignKey, Date, UniqueConstraint
)
from sqlalchemy import Boolean
from sqlalchemy.orm import relationship
from ..core.database import Base, BigIntPK


class Tribe(Base):
    __tablename__ = "tribes"
    id          = Column(BigIntPK, primary_key=True, autoincrement=True)
    nom         = Column(String(150), nullable=False, unique=True)
    region      = Column(String(100), nullable=True)
    description = Column(Text, nullable=True)
    langue      = Column(String(100), nullable=True)
    image       = Column(String(255), nullable=True)
    created_at  = Column(DateTime, default=datetime.utcnow)
    updated_at  = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    clans       = relationship("Clan", back_populates="tribe", cascade="all, delete")


class Clan(Base):
    __tablename__ = "clans"
    id          = Column(BigIntPK, primary_key=True, autoincrement=True)
    tribe_id    = Column(BigInteger, ForeignKey("tribes.id", ondelete="CASCADE"), nullable=False)
    nom         = Column(String(150), nullable=False)
    description = Column(Text, nullable=True)
    created_at  = Column(DateTime, default=datetime.utcnow)
    tribe       = relationship("Tribe", back_populates="clans")


class Family(Base):
    __tablename__ = "families"
    id          = Column(BigIntPK, primary_key=True, autoincrement=True)
    nom         = Column(String(200), nullable=False)
    owner_id    = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    visibilite  = Column(Enum("PRIVE", "PARTAGE", "PUBLIC"), nullable=False, default="PRIVE")
    description = Column(Text, nullable=True)
    created_at  = Column(DateTime, default=datetime.utcnow)
    updated_at  = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    owner   = relationship("User", back_populates="families")
    persons = relationship("Person", back_populates="family")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "nom": self.nom,
            "owner_id": self.owner_id,
            "visibilite": self.visibilite,
            "description": self.description,
            "created_at": str(self.created_at) if self.created_at else None,
        }


class Person(Base):
    __tablename__ = "persons"
    id              = Column(BigIntPK, primary_key=True, autoincrement=True)
    family_id       = Column(BigInteger, ForeignKey("families.id", ondelete="SET NULL"), nullable=True)
    linked_user_id  = Column(BigInteger, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    nom             = Column(String(150), nullable=False)
    prenom          = Column(String(150), nullable=True)
    sexe            = Column(Enum("M", "F", "INCONNU"), nullable=False, default="INCONNU")
    date_naissance  = Column(Date, nullable=True)
    date_deces      = Column(Date, nullable=True)
    vivant          = Column(SmallInteger, nullable=False, default=1)
    village_id      = Column(BigInteger, nullable=True)
    tribe_id        = Column(BigInteger, ForeignKey("tribes.id", ondelete="SET NULL"), nullable=True)
    clan_id         = Column(BigInteger, ForeignKey("clans.id", ondelete="SET NULL"), nullable=True)
    photo           = Column(String(255), nullable=True)
    notes           = Column(Text, nullable=True)

    lieu_naissance     = Column(String(200), nullable=True)
    village_origine    = Column(String(150), nullable=True)
    nationalite        = Column(String(100), nullable=True, default="Camerounais(e)")
    profession         = Column(String(150), nullable=True)
    nom_pere_texte     = Column(String(200), nullable=True)
    nom_mere_texte     = Column(String(200), nullable=True)

    visibilite                  = Column(Enum("PRIVE", "PARTAGE", "PUBLIC"), nullable=False, default="PRIVE")
    peut_voir                   = Column(Boolean, nullable=False, default=True)
    peut_modifier                = Column(Boolean, nullable=False, default=False)
    peut_ajouter_documents       = Column(Boolean, nullable=False, default=False)
    peut_ajouter_souvenirs       = Column(Boolean, nullable=False, default=True)
    peut_commenter               = Column(Boolean, nullable=False, default=True)

    created_by      = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at      = Column(DateTime, default=datetime.utcnow)
    updated_at      = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    family    = relationship("Family", back_populates="persons")
    documents = relationship("PersonDocument", back_populates="person", cascade="all, delete-orphan")
    memories  = relationship("PersonMemory", back_populates="person", cascade="all, delete-orphan")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "family_id": self.family_id,
            "nom": self.nom,
            "prenom": self.prenom,
            "sexe": self.sexe,
            "date_naissance": str(self.date_naissance) if self.date_naissance else None,
            "date_deces": str(self.date_deces) if self.date_deces else None,
            "vivant": bool(self.vivant),
            "photo": self.photo,
            "notes": self.notes,
            "lieu_naissance": self.lieu_naissance,
            "village_origine": self.village_origine,
            "nationalite": self.nationalite,
            "profession": self.profession,
            "nom_pere_texte": self.nom_pere_texte,
            "nom_mere_texte": self.nom_mere_texte,
            "visibilite": self.visibilite,
            "peut_voir": bool(self.peut_voir),
            "peut_modifier": bool(self.peut_modifier),
            "peut_ajouter_documents": bool(self.peut_ajouter_documents),
            "peut_ajouter_souvenirs": bool(self.peut_ajouter_souvenirs),
            "peut_commenter": bool(self.peut_commenter),
        }


class Relationship(Base):
    __tablename__ = "relationships"
    id                = Column(BigIntPK, primary_key=True, autoincrement=True)
    person_id         = Column(BigInteger, ForeignKey("persons.id", ondelete="CASCADE"), nullable=False)
    related_person_id = Column(BigInteger, ForeignKey("persons.id", ondelete="CASCADE"), nullable=False)
    type_relation     = Column(
        Enum("PERE", "MERE", "CONJOINT", "ENFANT", "FRERE_SOEUR", "GRAND_PARENT"),
        nullable=False
    )
    date_debut = Column(Date, nullable=True)
    date_fin   = Column(Date, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint("person_id", "related_person_id", "type_relation"),
    )


class PersonDocument(Base):
    __tablename__ = "person_documents"
    id            = Column(BigIntPK, primary_key=True, autoincrement=True)
    person_id     = Column(BigInteger, ForeignKey("persons.id", ondelete="CASCADE"), nullable=False)
    type_document = Column(Enum("ACTE_NAISSANCE", "ACTE_MARIAGE", "ACTE_DECES", "AUTRE"), nullable=False)
    nom_fichier   = Column(String(255), nullable=False)
    uploaded_by   = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at    = Column(DateTime, default=datetime.utcnow)

    person = relationship("Person", back_populates="documents")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "person_id": self.person_id,
            "type_document": self.type_document,
            "nom_fichier": self.nom_fichier,
            "created_at": str(self.created_at) if self.created_at else None,
        }


class PersonMemory(Base):
    __tablename__ = "person_memories"
    id           = Column(BigIntPK, primary_key=True, autoincrement=True)
    person_id    = Column(BigInteger, ForeignKey("persons.id", ondelete="CASCADE"), nullable=False)
    type         = Column(Enum("PHOTO", "VIDEO", "AUDIO"), nullable=False)
    nom_fichier  = Column(String(255), nullable=False)
    uploaded_by  = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at   = Column(DateTime, default=datetime.utcnow)

    person = relationship("Person", back_populates="memories")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "person_id": self.person_id,
            "type": self.type,
            "nom_fichier": self.nom_fichier,
            "created_at": str(self.created_at) if self.created_at else None,
        }


class FamilyShare(Base):
    __tablename__ = "family_shares"
    id         = Column(BigIntPK, primary_key=True, autoincrement=True)
    family_id  = Column(BigInteger, ForeignKey("families.id", ondelete="CASCADE"), nullable=False)
    user_id    = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    permission = Column(Enum("LECTURE", "EDITION"), nullable=False, default="LECTURE")
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (UniqueConstraint("family_id", "user_id"),)
