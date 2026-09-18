# app/schemas/admin.py

from pydantic import BaseModel, field_validator


class UserStatusUpdate(BaseModel):
    statut: str

    @field_validator("statut")
    @classmethod
    def _valid_statut(cls, v):
        if v not in ("ACTIF", "SUSPENDU"):
            raise ValueError("Statut invalide (ACTIF ou SUSPENDU attendu).")
        return v
