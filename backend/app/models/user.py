# app/models/user.py

from datetime import datetime
from sqlalchemy import (
    Column, BigInteger, String, Enum, Text,
    DateTime, SmallInteger, ForeignKey, Date, Index, Boolean
)
from sqlalchemy.orm import relationship
from ..core.database import Base, BigIntPK


class User(Base):
    __tablename__ = "users"

    id                = Column(BigIntPK, primary_key=True, autoincrement=True)
    nom               = Column(String(100), nullable=False)
    prenom            = Column(String(100), nullable=False)
    email             = Column(String(150), nullable=False, unique=True)
    telephone         = Column(String(20), nullable=True)
    sexe              = Column(Enum("M", "F", "AUTRE", name="user_sexe"), nullable=False)
    date_naissance    = Column(Date, nullable=True)
    mot_de_passe_hash = Column(String(255), nullable=False)
    role              = Column(
        Enum("ADMIN", "MODERATEUR", "UTILISATEUR", name="user_role"),
        nullable=False, default="UTILISATEUR"
    )
    photo_profil      = Column(String(255), nullable=True)
    biographie        = Column(Text, nullable=True)
    village_origine   = Column(String(150), nullable=True)
    region            = Column(String(100), nullable=True)
    departement       = Column(String(100), nullable=True)
    langue            = Column(String(100), nullable=True)
    profession        = Column(String(150), nullable=True)
    tribe_id          = Column(BigInteger, ForeignKey("tribes.id", ondelete="SET NULL"), nullable=True)
    clan_id           = Column(BigInteger, ForeignKey("clans.id", ondelete="SET NULL"), nullable=True)
    statut_auteur     = Column(Enum("UTILISATEUR", "PROFESSIONNEL", name="user_statut_auteur"), nullable=False, default="UTILISATEUR")
    certifie          = Column(Boolean, nullable=False, default=False)
    email_verifie     = Column(SmallInteger, nullable=False, default=0)
    token_verification = Column(String(255), nullable=True)
    statut            = Column(
        Enum("ACTIF", "SUSPENDU", "SUPPRIME", name="user_statut"),
        nullable=False, default="ACTIF"
    )
    derniere_connexion = Column(DateTime, nullable=True)
    created_at        = Column(DateTime, default=datetime.utcnow)
    updated_at        = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    refresh_tokens    = relationship("RefreshToken", back_populates="user", cascade="all, delete")
    families          = relationship("Family", back_populates="owner", cascade="all, delete")

    def to_public_dict(self) -> dict:
        return {
            "id": self.id,
            "nom": self.nom,
            "prenom": self.prenom,
            "email": self.email,
            "telephone": self.telephone,
            "sexe": self.sexe,
            "date_naissance": str(self.date_naissance) if self.date_naissance else None,
            "role": self.role,
            "photo_profil": self.photo_profil,
            "biographie": self.biographie,
            "village_origine": self.village_origine,
            "region": self.region,
            "departement": self.departement,
            "langue": self.langue,
            "profession": self.profession,
            "statut_auteur": self.statut_auteur,
            "certifie": bool(self.certifie),
            "email_verifie": self.email_verifie,
            "statut": self.statut,
            "created_at": str(self.created_at) if self.created_at else None,
        }


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id         = Column(BigIntPK, primary_key=True, autoincrement=True)
    user_id    = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token_hash = Column(String(255), nullable=False)
    user_agent = Column(String(255), nullable=True)
    ip_address = Column(String(45), nullable=True)
    expire_at  = Column(DateTime, nullable=False)
    revoked    = Column(SmallInteger, nullable=False, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="refresh_tokens")


class LoginAttempt(Base):
    __tablename__ = "login_attempts"

    id         = Column(BigIntPK, primary_key=True, autoincrement=True)
    email      = Column(String(150), nullable=False)
    ip_address = Column(String(45), nullable=False)
    succes     = Column(SmallInteger, nullable=False, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
