# app/schemas/family_chat.py

from pydantic import BaseModel, Field
from typing import Optional, List


class GroupCreate(BaseModel):
    nom:        str = Field(..., min_length=1, max_length=150)
    member_ids: List[int] = Field(default_factory=list)


class AddMemberRequest(BaseModel):
    user_id: int


class MessageCreate(BaseModel):
    contenu: Optional[str] = Field(None, max_length=4000)
