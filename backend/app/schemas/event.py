# app/schemas/event.py

from pydantic import BaseModel, Field
from typing import Optional
from datetime import date, time

TYPE_PATTERN = "^(ANNIVERSAIRE|ANNIVERSAIRE_DECES|MARIAGE|NAISSANCE|BAPTEME|CEREMONIE|REUNION|AUTRE)$"


class EventCreate(BaseModel):
    nom:                str  = Field(..., min_length=1, max_length=150)
    type_evenement:     str  = Field("AUTRE", pattern=TYPE_PATTERN)
    date_evenement:     date
    heure:              Optional[time] = None
    description:        Optional[str]  = Field(None, max_length=2000)
    personne_concernee: Optional[str]  = Field(None, max_length=150)


class EventUpdate(BaseModel):
    nom:                Optional[str]  = Field(None, max_length=150)
    type_evenement:     Optional[str]  = Field(None, pattern=TYPE_PATTERN)
    date_evenement:     Optional[date] = None
    heure:              Optional[time] = None
    description:        Optional[str]  = Field(None, max_length=2000)
    personne_concernee: Optional[str]  = Field(None, max_length=150)
