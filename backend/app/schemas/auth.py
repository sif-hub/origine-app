# app/schemas/auth.py

from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import date


class RegisterRequest(BaseModel):
    nom:            str       = Field(..., min_length=1, max_length=100)
    prenom:         str       = Field(..., min_length=1, max_length=100)
    email:          EmailStr
    telephone:      Optional[str] = None
    sexe:           str       = Field(..., pattern="^(M|F|AUTRE)$")
    date_naissance: Optional[date] = None
    mot_de_passe:   str       = Field(..., min_length=8)


class LoginRequest(BaseModel):
    email:       EmailStr
    mot_de_passe: str


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token:  str
    refresh_token: str
    token_type:    str = "bearer"


class UserPublic(BaseModel):
    id:              int
    nom:             str
    prenom:          str
    email:           str
    telephone:       Optional[str]
    sexe:            str
    date_naissance:  Optional[str]
    role:            str
    photo_profil:    Optional[str]
    biographie:      Optional[str]
    village_origine: Optional[str]
    region:          Optional[str]
    profession:      Optional[str]
    email_verifie:   int
    statut:          str

    class Config:
        from_attributes = True


class UpdateProfileRequest(BaseModel):
    nom:             Optional[str] = Field(None, max_length=100)
    prenom:          Optional[str] = Field(None, max_length=100)
    telephone:       Optional[str] = None
    biographie:      Optional[str] = Field(None, max_length=2000)
    village_origine: Optional[str] = Field(None, max_length=150)
    region:          Optional[str] = Field(None, max_length=100)
    departement:     Optional[str] = Field(None, max_length=100)
    langue:          Optional[str] = Field(None, max_length=100)
    profession:      Optional[str] = Field(None, max_length=150)


class ChangePasswordRequest(BaseModel):
    mot_de_passe_actuel:   str
    nouveau_mot_de_passe:  str = Field(..., min_length=8)
