# app/routers/uploads.py

from fastapi import APIRouter, Depends, HTTPException

from ..core.security import get_current_user
from ..services import storage_service

router = APIRouter(prefix="/uploads", tags=["Uploads"])

ALLOWED_FOLDERS = {"story_media", "person_memories", "family_messages"}


@router.get("/signature")
def upload_signature(folder: str = "story_media", user=Depends(get_current_user)):
    if folder not in ALLOWED_FOLDERS:
        raise HTTPException(status_code=400, detail="Dossier invalide.")
    return {"success": True, "data": storage_service.signed_upload_params(folder)}
