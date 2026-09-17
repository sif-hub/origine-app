# app/schemas/story.py

from pydantic import BaseModel, Field
from typing import Optional
from datetime import date

CATEGORIE_PATTERN = (
    "^(TRADITIONS_COUTUMES|HISTOIRE_PEUPLES|PERSONNALITES_FIGURES|"
    "LIEUX_PATRIMOINE|RITES_CEREMONIES|CONTES_LEGENDES|"
    "LANGUES_EXPRESSIONS|ART_MUSIQUE_DANSE|VIE_QUOTIDIENNE|AUTRE)$"
)


class StoryCreate(BaseModel):
    titre:         str  = Field(..., min_length=1, max_length=200)
    description:   str  = Field(..., min_length=1)
    date_histoire: Optional[date] = None
    region:        Optional[str]  = Field(None, max_length=100)
    village:       Optional[str]  = Field(None, max_length=150)
    categorie:     str  = Field("AUTRE", pattern=CATEGORIE_PATTERN)
    mots_cles:     Optional[str]  = Field(None, max_length=255)
    source:        Optional[str]  = Field(None, max_length=255)
    autoriser_tts: bool = True


class CommentCreate(BaseModel):
    contenu: str = Field(..., min_length=1, max_length=2000)


class ReportCreate(BaseModel):
    raison: Optional[str] = Field(None, max_length=1000)


class CertificationRequestCreate(BaseModel):
    type_professionnel: str = Field(..., pattern="^(GRIOT|GENEALOGISTE|HISTORIEN|AUTRE)$")
    description:        Optional[str] = Field(None, max_length=2000)
