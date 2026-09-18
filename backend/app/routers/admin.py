# app/routers/admin.py

from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from ..core.database import get_db
from ..core.security import require_admin
from ..schemas.admin import UserStatusUpdate
from ..services import admin_service as svc

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/stats")
def stats(db: Session = Depends(get_db), admin=Depends(require_admin)):
    return {"success": True, "data": svc.get_stats(db)}


@router.get("/users")
def list_users(q: Optional[str] = Query(None), db: Session = Depends(get_db), admin=Depends(require_admin)):
    users = svc.list_users(db, q)
    return {"success": True, "data": {"users": [u.to_public_dict() for u in users]}}


@router.put("/users/{user_id}/status")
def update_status(
    user_id: int,
    body: UserStatusUpdate,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    user = svc.update_user_status(db, user_id, body.statut, admin.id)
    return {"success": True, "data": {"user": user.to_public_dict()}}


@router.delete("/users/{user_id}", status_code=204)
def delete_user(user_id: int, db: Session = Depends(get_db), admin=Depends(require_admin)):
    svc.delete_user(db, user_id, admin.id)


@router.get("/reported-stories")
def reported_stories(db: Session = Depends(get_db), admin=Depends(require_admin)):
    return {"success": True, "data": {"items": svc.list_reported_stories(db)}}


@router.post("/reported-stories/{story_id}/dismiss")
def dismiss(story_id: int, db: Session = Depends(get_db), admin=Depends(require_admin)):
    svc.dismiss_reports(db, story_id)
    return {"success": True, "message": "Signalements ignorés."}


@router.delete("/reported-stories/{story_id}", status_code=204)
def remove_story(story_id: int, db: Session = Depends(get_db), admin=Depends(require_admin)):
    svc.admin_delete_story(db, story_id)
