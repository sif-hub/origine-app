# app/routers/profile.py

from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from ..core.database import get_db
from ..core.security import get_current_user, verify_password, hash_password
from ..schemas.auth import UpdateProfileRequest, ChangePasswordRequest
import os, secrets, shutil
from ..core.config import settings

router = APIRouter(prefix="/profile", tags=["Profil"])

ALLOWED_MIME = {"image/jpeg", "image/png", "image/webp"}


@router.get("")
def get_profile(current_user=Depends(get_current_user)):
    return {"success": True, "data": {"profile": current_user.to_public_dict()}}


@router.put("")
def update_profile(
    body: UpdateProfileRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(current_user, field, value)
    db.commit()
    db.refresh(current_user)
    return {"success": True, "message": "Profil mis à jour.", "data": {"profile": current_user.to_public_dict()}}


@router.post("/avatar")
async def upload_avatar(
    avatar: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if avatar.content_type not in ALLOWED_MIME:
        raise HTTPException(status_code=400, detail="Format non autorisé. Utilisez JPEG, PNG ou WEBP.")

    content = await avatar.read()
    if len(content) > settings.MAX_UPLOAD_SIZE:
        raise HTTPException(status_code=400, detail="Fichier trop volumineux (max 5 Mo).")

    ext = avatar.filename.rsplit(".", 1)[-1].lower() if "." in avatar.filename else "jpg"
    filename = f"{secrets.token_hex(16)}.{ext}"
    dest_dir = os.path.join(settings.UPLOAD_DIR, "avatars")
    os.makedirs(dest_dir, exist_ok=True)

    with open(os.path.join(dest_dir, filename), "wb") as f:
        f.write(content)

    current_user.photo_profil = filename
    db.commit()
    db.refresh(current_user)
    return {"success": True, "message": "Avatar mis à jour.", "data": {"profile": current_user.to_public_dict()}}


@router.post("/password")
def change_password(
    body: ChangePasswordRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if not verify_password(body.mot_de_passe_actuel, current_user.mot_de_passe_hash):
        raise HTTPException(status_code=400, detail="Mot de passe actuel incorrect.")

    current_user.mot_de_passe_hash = hash_password(body.nouveau_mot_de_passe)
    db.commit()
    return {"success": True, "message": "Mot de passe modifié avec succès."}
