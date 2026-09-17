# app/services/auth_service.py

import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from fastapi import HTTPException, status, Request
from sqlalchemy.orm import Session
from ..models.user import User, RefreshToken, LoginAttempt
from ..core.security import (
    hash_password, verify_password,
    create_access_token, create_refresh_token, decode_token
)
from ..core.config import settings

MAX_ATTEMPTS    = 5
LOCKOUT_MINUTES = 15


def _count_recent_failures(db: Session, email: str, ip: str) -> int:
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=LOCKOUT_MINUTES)
    return (
        db.query(LoginAttempt)
        .filter(
            LoginAttempt.email == email,
            LoginAttempt.ip_address == ip,
            LoginAttempt.succes == 0,
            LoginAttempt.created_at >= cutoff,
        )
        .count()
    )


def _record_attempt(db: Session, email: str, ip: str, success: bool):
    db.add(LoginAttempt(email=email, ip_address=ip, succes=1 if success else 0))
    db.commit()


def register_user(db: Session, data: dict, photo_filename: str = None) -> User:
    if db.query(User).filter(User.email == data["email"]).first():
        raise HTTPException(status_code=409, detail="Un compte existe déjà avec cet email.")

    user = User(
        nom=data["nom"],
        prenom=data["prenom"],
        email=data["email"],
        telephone=data.get("telephone"),
        sexe=data["sexe"],
        date_naissance=data.get("date_naissance"),
        mot_de_passe_hash=hash_password(data["mot_de_passe"]),
        photo_profil=photo_filename,
        token_verification=secrets.token_hex(32),
        email_verifie=1,   # Auto-validé en dev pour simplifier les tests
        statut="ACTIF",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def login_user(db: Session, email: str, password: str, ip: str) -> dict:
    if _count_recent_failures(db, email, ip) >= MAX_ATTEMPTS:
        raise HTTPException(
            status_code=429,
            detail=f"Trop de tentatives. Réessayez dans {LOCKOUT_MINUTES} minutes.",
        )

    user = db.query(User).filter(User.email == email).first()

    # Message générique (anti-énumération)
    if not user or not verify_password(password, user.mot_de_passe_hash):
        _record_attempt(db, email, ip, False)
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect.")

    if user.statut != "ACTIF":
        raise HTTPException(status_code=403, detail="Ce compte est suspendu.")

    if not user.email_verifie:
        raise HTTPException(status_code=403, detail="Confirmez votre email avant de vous connecter.")

    _record_attempt(db, email, ip, True)
    user.derniere_connexion = datetime.utcnow()
    db.commit()

    payload = {"sub": str(user.id), "role": user.role}
    access_token  = create_access_token(payload)
    refresh_token = create_refresh_token(payload)

    token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()
    expire_at  = datetime.now(timezone.utc) + timedelta(seconds=settings.JWT_REFRESH_TTL)

    db.add(RefreshToken(
        user_id=user.id,
        token_hash=token_hash,
        expire_at=expire_at,
    ))
    db.commit()

    return {
        "user":          user.to_public_dict(),
        "access_token":  access_token,
        "refresh_token": refresh_token,
    }


def refresh_tokens(db: Session, refresh_token: str) -> dict:
    payload = decode_token(refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Refresh token invalide ou expiré.")

    token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()
    stored = (
        db.query(RefreshToken)
        .filter(
            RefreshToken.token_hash == token_hash,
            RefreshToken.revoked == 0,
            RefreshToken.expire_at > datetime.utcnow(),
        )
        .first()
    )
    if not stored:
        raise HTTPException(status_code=401, detail="Refresh token révoqué ou expiré.")

    new_access = create_access_token({"sub": str(payload["sub"]), "role": payload["role"]})
    return {"access_token": new_access}


def logout_user(db: Session, refresh_token: str):
    token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()
    stored = db.query(RefreshToken).filter(RefreshToken.token_hash == token_hash).first()
    if stored:
        stored.revoked = 1
        db.commit()
