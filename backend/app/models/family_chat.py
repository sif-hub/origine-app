# app/models/family_chat.py

from datetime import datetime
from sqlalchemy import Column, BigInteger, String, Enum, Text, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from ..core.database import Base, BigIntPK


class FamilyGroup(Base):
    __tablename__ = "family_groups"
    id         = Column(BigIntPK, primary_key=True, autoincrement=True)
    nom        = Column(String(150), nullable=False)
    created_by = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    members  = relationship("FamilyGroupMember", back_populates="group", cascade="all, delete-orphan")
    messages = relationship("FamilyMessage", back_populates="group", cascade="all, delete-orphan")

    def to_dict(self, last_message=None) -> dict:
        return {
            "id": self.id,
            "nom": self.nom,
            "created_by": self.created_by,
            "members_count": len(self.members),
            "last_message": last_message.to_dict() if last_message else None,
            "created_at": str(self.created_at) if self.created_at else None,
        }


class FamilyGroupMember(Base):
    __tablename__ = "family_group_members"
    id        = Column(BigIntPK, primary_key=True, autoincrement=True)
    group_id  = Column(BigInteger, ForeignKey("family_groups.id", ondelete="CASCADE"), nullable=False)
    user_id   = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    joined_at = Column(DateTime, default=datetime.utcnow)

    group = relationship("FamilyGroup", back_populates="members")

    __table_args__ = (UniqueConstraint("group_id", "user_id"),)


class FamilyMessage(Base):
    __tablename__ = "family_messages"
    id           = Column(BigIntPK, primary_key=True, autoincrement=True)
    group_id     = Column(BigInteger, ForeignKey("family_groups.id", ondelete="CASCADE"), nullable=False)
    sender_id    = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    contenu      = Column(Text, nullable=True)
    type_message = Column(Enum("TEXT", "IMAGE"), nullable=False, default="TEXT")
    nom_fichier  = Column(String(255), nullable=True)
    created_at   = Column(DateTime, default=datetime.utcnow)

    group  = relationship("FamilyGroup", back_populates="messages")
    sender = relationship("User")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "group_id": self.group_id,
            "sender": {
                "id": self.sender.id,
                "nom": self.sender.nom,
                "prenom": self.sender.prenom,
                "photo_profil": self.sender.photo_profil,
            },
            "contenu": self.contenu,
            "type_message": self.type_message,
            "nom_fichier": self.nom_fichier,
            "created_at": str(self.created_at) if self.created_at else None,
        }
