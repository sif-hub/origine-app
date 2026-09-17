# app/models/push.py

from datetime import datetime
from sqlalchemy import Column, BigInteger, String, DateTime, ForeignKey
from ..core.database import Base, BigIntPK


class PushSubscription(Base):
    __tablename__ = "push_subscriptions"
    id         = Column(BigIntPK, primary_key=True, autoincrement=True)
    user_id    = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    # VARCHAR (pas Text) : nécessaire pour l'index unique sous MySQL, et les
    # endpoints de push (FCM/Mozilla) tiennent largement sous 500 caractères.
    endpoint   = Column(String(500), nullable=False, unique=True)
    p256dh     = Column(String(255), nullable=False)
    auth       = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
