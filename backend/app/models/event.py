# app/models/event.py

from datetime import datetime
from sqlalchemy import Column, BigInteger, String, Enum, Text, DateTime, Date, Time, ForeignKey
from ..core.database import Base, BigIntPK

TYPES_EVENEMENT = (
    "ANNIVERSAIRE", "ANNIVERSAIRE_DECES", "MARIAGE", "NAISSANCE",
    "BAPTEME", "CEREMONIE", "REUNION", "AUTRE",
)


class FamilyEvent(Base):
    __tablename__ = "family_events"
    id                  = Column(BigIntPK, primary_key=True, autoincrement=True)
    created_by          = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    nom                 = Column(String(150), nullable=False)
    type_evenement      = Column(Enum(*TYPES_EVENEMENT), nullable=False, default="AUTRE")
    date_evenement      = Column(Date, nullable=False)
    heure               = Column(Time, nullable=True)
    description         = Column(Text, nullable=True)
    personne_concernee  = Column(String(150), nullable=True)
    created_at          = Column(DateTime, default=datetime.utcnow)

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "nom": self.nom,
            "type_evenement": self.type_evenement,
            "date_evenement": str(self.date_evenement) if self.date_evenement else None,
            "heure": self.heure.strftime("%H:%M") if self.heure else None,
            "description": self.description,
            "personne_concernee": self.personne_concernee,
            "created_at": str(self.created_at) if self.created_at else None,
        }
