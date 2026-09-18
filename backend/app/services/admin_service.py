# app/services/admin_service.py

from typing import Optional

from fastapi import HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session

from ..models.user import User
from ..models.genealogy import Family
from ..models.story import Story, StoryReport, CertificationRequest
from ..models.family_chat import FamilyGroup, FamilyMessage


def get_stats(db: Session) -> dict:
    return {
        "utilisateurs": db.query(User).count(),
        "familles": db.query(Family).count(),
        "histoires": db.query(Story).count(),
        "groupes_familiaux": db.query(FamilyGroup).count(),
        "messages": db.query(FamilyMessage).count(),
        "certifications_en_attente": db.query(CertificationRequest)
            .filter(CertificationRequest.statut == "EN_ATTENTE").count(),
        "histoires_signalees": db.query(StoryReport.story_id).distinct().count(),
    }


def list_users(db: Session, q: Optional[str] = None):
    query = db.query(User)
    if q:
        like = f"%{q}%"
        query = query.filter(or_(User.nom.ilike(like), User.prenom.ilike(like), User.email.ilike(like)))
    return query.order_by(User.created_at.desc()).limit(200).all()


def update_user_status(db: Session, user_id: int, statut: str, admin_id: int) -> User:
    if user_id == admin_id:
        raise HTTPException(status_code=400, detail="Vous ne pouvez pas modifier votre propre statut.")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    user.statut = statut
    db.commit()
    db.refresh(user)
    return user


def delete_user(db: Session, user_id: int, admin_id: int) -> None:
    if user_id == admin_id:
        raise HTTPException(status_code=400, detail="Vous ne pouvez pas supprimer votre propre compte.")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    db.delete(user)
    db.commit()


def list_reported_stories(db: Session):
    story_ids = [row[0] for row in db.query(StoryReport.story_id).distinct().all()]
    if not story_ids:
        return []
    stories = db.query(Story).filter(Story.id.in_(story_ids)).all()
    result = []
    for story in stories:
        reports = db.query(StoryReport).filter(StoryReport.story_id == story.id).all()
        result.append({
            "story": story.to_dict(),
            "reports": [
                {"id": r.id, "raison": r.raison, "user_id": r.user_id, "created_at": str(r.created_at)}
                for r in reports
            ],
        })
    return result


def dismiss_reports(db: Session, story_id: int) -> None:
    db.query(StoryReport).filter(StoryReport.story_id == story_id).delete()
    db.commit()


def admin_delete_story(db: Session, story_id: int) -> None:
    story = db.query(Story).filter(Story.id == story_id).first()
    if not story:
        raise HTTPException(status_code=404, detail="Histoire introuvable.")
    db.delete(story)
    db.commit()
