# app/services/push_service.py

import json
from sqlalchemy.orm import Session
from pywebpush import webpush, WebPushException
from ..core.config import settings
from ..models.push import PushSubscription
from ..models.family_chat import FamilyGroupMember, FamilyGroup


def save_subscription(db: Session, user_id: int, endpoint: str, p256dh: str, auth: str) -> PushSubscription:
    existing = db.query(PushSubscription).filter(PushSubscription.endpoint == endpoint).first()
    if existing:
        existing.user_id = user_id
        existing.p256dh = p256dh
        existing.auth = auth
        db.commit()
        db.refresh(existing)
        return existing

    subscription = PushSubscription(user_id=user_id, endpoint=endpoint, p256dh=p256dh, auth=auth)
    db.add(subscription)
    db.commit()
    db.refresh(subscription)
    return subscription


def remove_subscription(db: Session, endpoint: str):
    db.query(PushSubscription).filter(PushSubscription.endpoint == endpoint).delete()
    db.commit()


def _send_one(db: Session, subscription: PushSubscription, payload: dict) -> None:
    try:
        webpush(
            subscription_info={
                "endpoint": subscription.endpoint,
                "keys": {"p256dh": subscription.p256dh, "auth": subscription.auth},
            },
            data=json.dumps(payload),
            vapid_private_key=settings.VAPID_PRIVATE_KEY,
            vapid_claims={"sub": settings.VAPID_CLAIMS_EMAIL},
        )
    except WebPushException as e:
        status_code = e.response.status_code if e.response is not None else None
        if status_code in (404, 410):
            # Abonnement expiré ou révoqué côté navigateur : on le supprime.
            db.query(PushSubscription).filter(PushSubscription.id == subscription.id).delete()
            db.commit()
    except Exception:
        # Un envoi qui échoue ne doit jamais faire échouer l'envoi du message.
        pass


def notify_group_message(db: Session, group_id: int, sender_id: int, message) -> None:
    if not settings.VAPID_PRIVATE_KEY or not settings.VAPID_PUBLIC_KEY:
        return

    group = db.query(FamilyGroup).filter(FamilyGroup.id == group_id).first()
    if not group:
        return

    member_ids = [
        m.user_id for m in
        db.query(FamilyGroupMember).filter(
            FamilyGroupMember.group_id == group_id,
            FamilyGroupMember.user_id != sender_id,
        ).all()
    ]
    if not member_ids:
        return

    body = message.contenu if message.contenu else "📷 Photo"
    sender_name = f"{message.sender.prenom or ''} {message.sender.nom}".strip()
    payload = {
        "title": group.nom,
        "body": f"{sender_name} : {body}"[:150],
        "group_id": group_id,
    }

    subscriptions = db.query(PushSubscription).filter(PushSubscription.user_id.in_(member_ids)).all()
    for subscription in subscriptions:
        _send_one(db, subscription, payload)
