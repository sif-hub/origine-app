# app/routers/ai.py

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..core.database import get_db
from ..core.security import get_current_user
from ..schemas.ai import (
    ChatRequest, NaturalSearchRequest,
    TraditionRequest, NameMeaningRequest, ClanRequest,
    SummarizeRequest, NarrativeRequest
)
from ..services import ai_service as svc
from ..models.genealogy import Person, Family

router = APIRouter(prefix="/ai", tags=["ORIGINE AI"])


@router.post("/chat")
def chat(body: ChatRequest, db=Depends(get_db), user=Depends(get_current_user)):
    historique = [m.model_dump() for m in body.historique]
    reponse = svc.chat(db, body.message, historique, user.id)
    return {"success": True, "data": {"reponse": reponse}}


@router.post("/search")
def natural_search(body: NaturalSearchRequest, db=Depends(get_db), user=Depends(get_current_user)):
    criteres = svc.natural_search(db, body.requete, user.id)

    filtres = criteres.get("filtres", {})
    query = db.query(Person)
    if filtres.get("nom"):
        query = query.filter(Person.nom.ilike(f"%{filtres['nom']}%"))
    if filtres.get("prenom"):
        query = query.filter(Person.prenom.ilike(f"%{filtres['prenom']}%"))
    resultats = query.limit(30).all()

    return {
        "success": True,
        "data": {
            "interpretation": criteres,
            "resultats": [p.to_dict() for p in resultats],
        },
    }


@router.post("/culture/tradition")
def explain_tradition(body: TraditionRequest, db=Depends(get_db), user=Depends(get_current_user)):
    result = svc.explain_tradition(db, body.nom, body.region, user.id)
    return {"success": True, "data": {"explication": result}}


@router.post("/culture/name-meaning")
def explain_name(body: NameMeaningRequest, db=Depends(get_db), user=Depends(get_current_user)):
    result = svc.explain_name(db, body.nom, body.tribu, user.id)
    return {"success": True, "data": {"explication": result}}


@router.post("/culture/clan")
def explain_clan(body: ClanRequest, db=Depends(get_db), user=Depends(get_current_user)):
    result = svc.explain_clan(db, body.nom, body.tribu, user.id)
    return {"success": True, "data": {"explication": result}}


@router.post("/history/summarize")
def summarize(body: SummarizeRequest, db=Depends(get_db), user=Depends(get_current_user)):
    result = svc.summarize_story(db, body.contenu, user.id)
    return {"success": True, "data": {"resume": result}}


@router.post("/history/narrative")
def narrative(body: NarrativeRequest, db=Depends(get_db), user=Depends(get_current_user)):
    result = svc.draft_narrative(db, body.notes, user.id)
    return {"success": True, "data": {"recit": result}}
