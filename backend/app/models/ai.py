# app/models/ai.py

from datetime import datetime
from sqlalchemy import (
    Column, BigInteger, String, Enum, Text,
    DateTime, SmallInteger, ForeignKey, Integer, JSON
)
from ..core.database import Base, BigIntPK


class AIProvider(Base):
    __tablename__ = "ai_providers"
    id          = Column(BigIntPK, primary_key=True, autoincrement=True)
    nom         = Column(String(50), nullable=False, unique=True)
    actif       = Column(SmallInteger, nullable=False, default=1)
    config_json = Column(JSON, nullable=True)
    created_at  = Column(DateTime, default=datetime.utcnow)


class AILog(Base):
    __tablename__ = "ai_logs"
    id           = Column(BigIntPK, primary_key=True, autoincrement=True)
    user_id      = Column(BigInteger, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    provider_id  = Column(BigInteger, ForeignKey("ai_providers.id", ondelete="SET NULL"), nullable=True)
    type_requete = Column(
        Enum("GENEALOGIE", "HISTOIRE", "CULTURE", "RECHERCHE_NATURELLE", "CHATBOT", name="ai_type_requete"),
        nullable=False
    )
    prompt     = Column(Text, nullable=True)
    reponse    = Column(Text, nullable=True)
    statut     = Column(Enum("SUCCES", "ECHEC", name="ai_log_statut"), nullable=False, default="SUCCES")
    duree_ms   = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
