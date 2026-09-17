# app/routers/family_chat.py

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from ..core.database import get_db
from ..core.security import get_current_user
from ..schemas.family_chat import GroupCreate, AddMemberRequest, MessageCreate
from ..services import family_chat_service as svc
from ..services import push_service
from ..services.storage_service import save_upload as _save_upload

router = APIRouter(tags=["Famille"])

ALLOWED_IMAGE_MIME = {"image/jpeg", "image/png", "image/webp"}


# ── GROUPES ─────────────────────────────────────────────────────────────

@router.post("/family-groups", status_code=201)
def create_group(body: GroupCreate, db=Depends(get_db), user=Depends(get_current_user)):
    group = svc.create_group(db, body.nom, user.id, body.member_ids)
    return {"success": True, "message": "Groupe créé.", "data": {"group": group.to_dict()}}


@router.get("/family-groups")
def list_groups(db=Depends(get_db), user=Depends(get_current_user)):
    pairs = svc.get_my_groups(db, user.id)
    return {"success": True, "data": {"groups": [g.to_dict(last_message=lm) for g, lm in pairs]}}


@router.get("/family-groups/{group_id}")
def get_group(group_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    group = svc.check_membership(db, group_id, user.id)
    return {"success": True, "data": {"group": group.to_dict()}}


@router.post("/family-groups/{group_id}/members", status_code=201)
def add_member(group_id: int, body: AddMemberRequest, db=Depends(get_db), user=Depends(get_current_user)):
    svc.add_member(db, group_id, body.user_id, user.id)
    return {"success": True, "message": "Membre ajouté."}


# ── MESSAGES ────────────────────────────────────────────────────────────

@router.post("/family-groups/{group_id}/messages", status_code=201)
async def send_message(
    group_id: int,
    contenu: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    db=Depends(get_db), user=Depends(get_current_user),
):
    if not contenu and not (image and image.filename):
        raise HTTPException(status_code=400, detail="Le message doit contenir du texte ou une image.")

    type_message = "TEXT"
    nom_fichier = None
    if image is not None and image.filename:
        if image.content_type not in ALLOWED_IMAGE_MIME:
            raise HTTPException(status_code=400, detail="Format d'image non autorisé.")
        nom_fichier = await _save_upload(image, "family_messages")
        type_message = "IMAGE"

    message = svc.send_message(db, group_id, user.id, contenu, type_message, nom_fichier)
    push_service.notify_group_message(db, group_id, user.id, message)
    return {"success": True, "data": {"message": message.to_dict()}}


@router.get("/family-groups/{group_id}/messages")
def list_messages(
    group_id: int, limit: int = 50, offset: int = 0,
    db=Depends(get_db), user=Depends(get_current_user),
):
    messages = svc.get_messages(db, group_id, user.id, limit=limit, offset=offset)
    return {"success": True, "data": {"messages": [m.to_dict() for m in messages]}}


# ── RECHERCHE D'UTILISATEURS (pour ajouter des membres) ─────────────────

@router.get("/users/search")
def search_users(q: str, db=Depends(get_db), user=Depends(get_current_user)):
    if len(q.strip()) < 2:
        return {"success": True, "data": {"users": []}}
    users = svc.search_users(db, q.strip(), user.id)
    return {"success": True, "data": {"users": [u.to_public_dict() for u in users]}}
