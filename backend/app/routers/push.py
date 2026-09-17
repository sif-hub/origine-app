# app/routers/push.py

from fastapi import APIRouter, Depends
from ..core.database import get_db
from ..core.security import get_current_user
from ..core.config import settings
from ..schemas.push import SubscriptionCreate, UnsubscribeRequest
from ..services import push_service as svc

router = APIRouter(prefix="/push", tags=["Notifications"])


@router.get("/vapid-public-key")
def get_vapid_public_key():
    return {"success": True, "data": {"public_key": settings.VAPID_PUBLIC_KEY}}


@router.post("/subscribe", status_code=201)
def subscribe(body: SubscriptionCreate, db=Depends(get_db), user=Depends(get_current_user)):
    svc.save_subscription(db, user.id, body.endpoint, body.keys.p256dh, body.keys.auth)
    return {"success": True, "message": "Abonnement enregistré."}


@router.post("/unsubscribe")
def unsubscribe(body: UnsubscribeRequest, db=Depends(get_db), user=Depends(get_current_user)):
    svc.remove_subscription(db, body.endpoint)
    return {"success": True, "message": "Abonnement supprimé."}
