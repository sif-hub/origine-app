# app/routers/auth.py

from fastapi import APIRouter, Depends, Request, Form, File, UploadFile, HTTPException
from pydantic import ValidationError
from sqlalchemy.orm import Session
from ..core.database import get_db
from ..core.security import get_current_user
from ..schemas.auth import (
    RegisterRequest, LoginRequest, RefreshRequest,
    UpdateProfileRequest, ChangePasswordRequest
)
from ..services import auth_service
from ..services.storage_service import save_upload
from ..core.security import verify_password, hash_password

router = APIRouter(prefix="/auth", tags=["Authentification"])

ALLOWED_PHOTO_MIME = {"image/jpeg", "image/png", "image/webp"}


@router.post("/register", status_code=201)
async def register(
    nom: str = Form(...),
    prenom: str = Form(...),
    email: str = Form(...),
    telephone: str | None = Form(None),
    sexe: str = Form(...),
    date_naissance: str | None = Form(None),
    mot_de_passe: str = Form(...),
    photo: UploadFile | None = File(None),
    db: Session = Depends(get_db),
):
    try:
        body = RegisterRequest(
            nom=nom, prenom=prenom, email=email, telephone=telephone,
            sexe=sexe, date_naissance=date_naissance or None, mot_de_passe=mot_de_passe,
        )
    except ValidationError as e:
        raise HTTPException(status_code=422, detail=e.errors())

    photo_filename = None
    if photo is not None and photo.filename:
        if photo.content_type not in ALLOWED_PHOTO_MIME:
            raise HTTPException(status_code=400, detail="Format non autorisé. Utilisez JPEG, PNG ou WEBP.")
        photo_filename = await save_upload(photo, "avatars")

    user = auth_service.register_user(db, body.model_dump(), photo_filename=photo_filename)
    return {
        "success": True,
        "message": "Inscription réussie. Votre compte est activé.",
        "data": {"user": user.to_public_dict()},
    }


@router.post("/login")
def login(body: LoginRequest, request: Request, db: Session = Depends(get_db)):
    ip = request.client.host if request.client else "0.0.0.0"
    result = auth_service.login_user(db, body.email, body.mot_de_passe, ip)
    return {"success": True, "message": "Connexion réussie.", "data": result}


@router.post("/refresh")
def refresh(body: RefreshRequest, db: Session = Depends(get_db)):
    result = auth_service.refresh_tokens(db, body.refresh_token)
    return {"success": True, "message": "Token rafraîchi.", "data": result}


@router.post("/logout")
def logout(body: RefreshRequest, db: Session = Depends(get_db)):
    auth_service.logout_user(db, body.refresh_token)
    return {"success": True, "message": "Déconnexion réussie."}


@router.get("/me")
def me(current_user=Depends(get_current_user)):
    return {"success": True, "data": {"user": current_user.to_public_dict()}}
