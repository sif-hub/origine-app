# app/models/story.py

from datetime import datetime
from sqlalchemy import (
    Column, BigInteger, String, Enum, Text,
    DateTime, ForeignKey, Date, Boolean, UniqueConstraint
)
from sqlalchemy.orm import relationship
from ..core.database import Base, BigIntPK

CATEGORIES = (
    "TRADITIONS_COUTUMES", "HISTOIRE_PEUPLES", "PERSONNALITES_FIGURES",
    "LIEUX_PATRIMOINE", "RITES_CEREMONIES", "CONTES_LEGENDES",
    "LANGUES_EXPRESSIONS", "ART_MUSIQUE_DANSE", "VIE_QUOTIDIENNE", "AUTRE",
)


class Story(Base):
    __tablename__ = "stories"
    id             = Column(BigIntPK, primary_key=True, autoincrement=True)
    author_id      = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    titre          = Column(String(200), nullable=False)
    description    = Column(Text, nullable=False)
    date_histoire  = Column(Date, nullable=True)
    region         = Column(String(100), nullable=True)
    village        = Column(String(150), nullable=True)
    categorie      = Column(Enum(*CATEGORIES), nullable=False, default="AUTRE")
    mots_cles      = Column(String(255), nullable=True)
    source         = Column(String(255), nullable=True)
    autoriser_tts  = Column(Boolean, nullable=False, default=True)
    created_at     = Column(DateTime, default=datetime.utcnow)
    updated_at     = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    author   = relationship("User")
    media    = relationship("StoryMedia", back_populates="story", cascade="all, delete-orphan")
    likes    = relationship("StoryLike", back_populates="story", cascade="all, delete-orphan")
    comments = relationship("StoryComment", back_populates="story", cascade="all, delete-orphan")

    def to_dict(self, viewer_id: int = None) -> dict:
        author = self.author
        return {
            "id": self.id,
            "author": {
                "id": author.id,
                "nom": author.nom,
                "prenom": author.prenom,
                "photo_profil": author.photo_profil,
                "certifie": bool(author.certifie),
                "statut_auteur": author.statut_auteur,
            },
            "titre": self.titre,
            "description": self.description,
            "date_histoire": str(self.date_histoire) if self.date_histoire else None,
            "region": self.region,
            "village": self.village,
            "categorie": self.categorie,
            "mots_cles": self.mots_cles,
            "source": self.source,
            "autoriser_tts": bool(self.autoriser_tts),
            "media": [m.to_dict() for m in self.media],
            "likes_count": len(self.likes),
            "comments_count": len(self.comments),
            "liked_by_me": any(l.user_id == viewer_id for l in self.likes) if viewer_id else False,
            "created_at": str(self.created_at) if self.created_at else None,
        }


class StoryMedia(Base):
    __tablename__ = "story_media"
    id          = Column(BigIntPK, primary_key=True, autoincrement=True)
    story_id    = Column(BigInteger, ForeignKey("stories.id", ondelete="CASCADE"), nullable=False)
    type        = Column(Enum("PHOTO", "VIDEO", "AUDIO"), nullable=False)
    nom_fichier = Column(String(255), nullable=False)
    created_at  = Column(DateTime, default=datetime.utcnow)

    story = relationship("Story", back_populates="media")

    def to_dict(self) -> dict:
        return {"id": self.id, "type": self.type, "nom_fichier": self.nom_fichier}


class StoryLike(Base):
    __tablename__ = "story_likes"
    id         = Column(BigIntPK, primary_key=True, autoincrement=True)
    story_id   = Column(BigInteger, ForeignKey("stories.id", ondelete="CASCADE"), nullable=False)
    user_id    = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    story = relationship("Story", back_populates="likes")

    __table_args__ = (UniqueConstraint("story_id", "user_id"),)


class StoryComment(Base):
    __tablename__ = "story_comments"
    id         = Column(BigIntPK, primary_key=True, autoincrement=True)
    story_id   = Column(BigInteger, ForeignKey("stories.id", ondelete="CASCADE"), nullable=False)
    user_id    = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    contenu    = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    story  = relationship("Story", back_populates="comments")
    author = relationship("User")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "story_id": self.story_id,
            "contenu": self.contenu,
            "author": {
                "id": self.author.id,
                "nom": self.author.nom,
                "prenom": self.author.prenom,
                "photo_profil": self.author.photo_profil,
            },
            "created_at": str(self.created_at) if self.created_at else None,
        }


class StoryReport(Base):
    __tablename__ = "story_reports"
    id         = Column(BigIntPK, primary_key=True, autoincrement=True)
    story_id   = Column(BigInteger, ForeignKey("stories.id", ondelete="CASCADE"), nullable=False)
    user_id    = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    raison     = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class CertificationRequest(Base):
    __tablename__ = "certification_requests"
    id                 = Column(BigIntPK, primary_key=True, autoincrement=True)
    user_id            = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    type_professionnel = Column(Enum("GRIOT", "GENEALOGISTE", "HISTORIEN", "AUTRE"), nullable=False)
    description        = Column(Text, nullable=True)
    document_fichier   = Column(String(255), nullable=False)
    statut             = Column(Enum("EN_ATTENTE", "APPROUVEE", "REJETEE"), nullable=False, default="EN_ATTENTE")
    created_at         = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "user": {
                "id": self.user.id,
                "nom": self.user.nom,
                "prenom": self.user.prenom,
                "email": self.user.email,
            } if self.user else None,
            "type_professionnel": self.type_professionnel,
            "description": self.description,
            "document_fichier": self.document_fichier,
            "statut": self.statut,
            "created_at": str(self.created_at) if self.created_at else None,
        }
