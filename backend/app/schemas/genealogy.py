# app/schemas/genealogy.py

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date


class FamilyCreate(BaseModel):
    nom:         str  = Field(..., min_length=1, max_length=200)
    visibilite:  str  = Field("PRIVE", pattern="^(PRIVE|PARTAGE|PUBLIC)$")
    description: Optional[str] = None


class FamilyUpdate(BaseModel):
    nom:         Optional[str] = Field(None, min_length=1, max_length=200)
    visibilite:  Optional[str] = Field(None, pattern="^(PRIVE|PARTAGE|PUBLIC)$")
    description: Optional[str] = None


class PersonCreate(BaseModel):
    nom:             str  = Field(..., min_length=1, max_length=150)
    prenom:          Optional[str] = Field(None, max_length=150)
    sexe:            str  = Field("INCONNU", pattern="^(M|F|INCONNU)$")
    date_naissance:  Optional[date] = None
    date_deces:      Optional[date] = None
    family_id:       Optional[int]  = None
    notes:           Optional[str]  = None
    photo:           Optional[str]  = Field(None, max_length=255)
    lieu_naissance:  Optional[str]  = Field(None, max_length=200)
    village_origine: Optional[str]  = Field(None, max_length=150)
    nationalite:     Optional[str]  = Field(None, max_length=100)
    profession:      Optional[str]  = Field(None, max_length=150)
    nom_pere_texte:  Optional[str]  = Field(None, max_length=200)
    nom_mere_texte:  Optional[str]  = Field(None, max_length=200)


class PersonUpdate(BaseModel):
    nom:             Optional[str]  = Field(None, max_length=150)
    prenom:          Optional[str]  = Field(None, max_length=150)
    sexe:            Optional[str]  = Field(None, pattern="^(M|F|INCONNU)$")
    date_naissance:  Optional[date] = None
    date_deces:      Optional[date] = None
    vivant:          Optional[bool] = None
    notes:           Optional[str]  = None
    photo:           Optional[str]  = Field(None, max_length=255)
    lieu_naissance:  Optional[str]  = Field(None, max_length=200)
    village_origine: Optional[str]  = Field(None, max_length=150)
    nationalite:     Optional[str]  = Field(None, max_length=100)
    profession:      Optional[str]  = Field(None, max_length=150)
    nom_pere_texte:  Optional[str]  = Field(None, max_length=200)
    nom_mere_texte:  Optional[str]  = Field(None, max_length=200)


class PersonPrivacyUpdate(BaseModel):
    visibilite:             Optional[str]  = Field(None, pattern="^(PRIVE|PARTAGE|PUBLIC)$")
    peut_voir:               Optional[bool] = None
    peut_modifier:           Optional[bool] = None
    peut_ajouter_documents:  Optional[bool] = None
    peut_ajouter_souvenirs:  Optional[bool] = None
    peut_commenter:          Optional[bool] = None


class LinkRequest(BaseModel):
    related_person_id: int
    type:              str = Field(..., pattern="^(PERE|MERE|CONJOINT|ENFANT|FRERE_SOEUR|GRAND_PARENT)$")
    date_debut:        Optional[date] = None
    date_fin:          Optional[date] = None


class MergeFamiliesRequest(BaseModel):
    source_family_id: int
    target_family_id: int


class ShareFamilyRequest(BaseModel):
    user_id:    int
    permission: str = Field("LECTURE", pattern="^(LECTURE|EDITION)$")
