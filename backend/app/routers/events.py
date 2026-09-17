# app/routers/events.py

from typing import Optional
from datetime import date

from fastapi import APIRouter, Depends
from ..core.database import get_db
from ..core.security import get_current_user
from ..schemas.event import EventCreate, EventUpdate
from ..services import event_service as svc

router = APIRouter(tags=["Calendrier"])


@router.post("/events", status_code=201)
def create_event(body: EventCreate, db=Depends(get_db), user=Depends(get_current_user)):
    event = svc.create_event(db, body.model_dump(), user.id)
    return {"success": True, "message": "Événement créé.", "data": {"event": event.to_dict()}}


@router.get("/events")
def list_events(
    start: Optional[date] = None, end: Optional[date] = None,
    db=Depends(get_db), user=Depends(get_current_user),
):
    events = svc.get_my_events(db, user.id, start=start, end=end)
    return {"success": True, "data": {"events": [e.to_dict() for e in events]}}


@router.get("/events/{event_id}")
def get_event(event_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    event = svc.get_event(db, event_id, user.id)
    return {"success": True, "data": {"event": event.to_dict()}}


@router.put("/events/{event_id}")
def update_event(event_id: int, body: EventUpdate, db=Depends(get_db), user=Depends(get_current_user)):
    event = svc.update_event(db, event_id, user.id, body.model_dump(exclude_none=True))
    return {"success": True, "message": "Événement mis à jour.", "data": {"event": event.to_dict()}}


@router.delete("/events/{event_id}", status_code=204)
def delete_event(event_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    svc.delete_event(db, event_id, user.id)
