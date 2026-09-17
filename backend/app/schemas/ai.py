# app/schemas/ai.py

from pydantic import BaseModel, Field
from typing import Optional, List


class ChatMessage(BaseModel):
    role:    str
    content: str


class ChatRequest(BaseModel):
    message:    str = Field(..., min_length=1, max_length=2000)
    historique: List[ChatMessage] = []


class NaturalSearchRequest(BaseModel):
    requete:   str = Field(..., min_length=1)
    family_id: Optional[int] = None


class TraditionRequest(BaseModel):
    nom:    str = Field(..., min_length=1)
    region: Optional[str] = None


class NameMeaningRequest(BaseModel):
    nom:   str = Field(..., min_length=1)
    tribu: Optional[str] = None


class ClanRequest(BaseModel):
    nom:   str = Field(..., min_length=1)
    tribu: Optional[str] = None


class SummarizeRequest(BaseModel):
    contenu: str = Field(..., min_length=10, max_length=5000)


class NarrativeRequest(BaseModel):
    notes: str = Field(..., min_length=10)


class FamilyConnectionRequest(BaseModel):
    family_a_id: int
    family_b_id: int
