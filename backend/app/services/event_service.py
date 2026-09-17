# app/services/event_service.py

from sqlalchemy.orm import Session
from fastapi import HTTPException
from ..models.event import FamilyEvent
from typing import Optional
from datetime import date


def create_event(db: Session, data: dict, user_id: int) -> FamilyEvent:
    event = FamilyEvent(
        created_by=user_id,
        nom=data["nom"],
        type_evenement=data.get("type_evenement", "AUTRE"),
        date_evenement=data["date_evenement"],
        heure=data.get("heure"),
        description=data.get("description"),
        personne_concernee=data.get("personne_concernee"),
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return event


def get_my_events(db: Session, user_id: int, start: Optional[date] = None, end: Optional[date] = None):
    query = db.query(FamilyEvent).filter(FamilyEvent.created_by == user_id)
    if start:
        query = query.filter(FamilyEvent.date_evenement >= start)
    if end:
        query = query.filter(FamilyEvent.date_evenement <= end)
    return query.order_by(FamilyEvent.date_evenement.asc()).all()


def _get_owned_event(db: Session, event_id: int, user_id: int) -> FamilyEvent:
    event = db.query(FamilyEvent).filter(FamilyEvent.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Événement introuvable.")
    if event.created_by != user_id:
        raise HTTPException(status_code=403, detail="Cet événement ne vous appartient pas.")
    return event


def get_event(db: Session, event_id: int, user_id: int) -> FamilyEvent:
    return _get_owned_event(db, event_id, user_id)


def update_event(db: Session, event_id: int, user_id: int, data: dict) -> FamilyEvent:
    event = _get_owned_event(db, event_id, user_id)
    for field, value in data.items():
        setattr(event, field, value)
    db.commit()
    db.refresh(event)
    return event


def delete_event(db: Session, event_id: int, user_id: int):
    event = _get_owned_event(db, event_id, user_id)
    db.delete(event)
    db.commit()
