# app/services/story_service.py

from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException
from ..models.story import Story, StoryMedia, StoryLike, StoryComment, StoryReport, CertificationRequest
from ..models.user import User
from typing import Optional


def _story_query(db: Session):
    return db.query(Story).options(
        joinedload(Story.author), joinedload(Story.media), joinedload(Story.likes)
    )


def create_story(db: Session, data: dict, author_id: int) -> Story:
    story = Story(
        author_id=author_id,
        titre=data["titre"],
        description=data["description"],
        date_histoire=data.get("date_histoire"),
        region=data.get("region"),
        village=data.get("village"),
        categorie=data.get("categorie", "AUTRE"),
        mots_cles=data.get("mots_cles"),
        source=data.get("source"),
        autoriser_tts=data.get("autoriser_tts", True),
    )
    db.add(story)
    db.commit()
    db.refresh(story)
    return story


def get_feed(db: Session, limit: int = 20, offset: int = 0, q: Optional[str] = None):
    query = _story_query(db)
    if q and q.strip():
        like = f"%{q.strip()}%"
        query = query.join(User, Story.author_id == User.id).filter(or_(
            Story.titre.ilike(like), Story.description.ilike(like),
            Story.mots_cles.ilike(like), Story.region.ilike(like),
            Story.village.ilike(like), User.nom.ilike(like), User.prenom.ilike(like),
        ))
    return query.order_by(Story.created_at.desc()).offset(offset).limit(limit).all()


def get_story(db: Session, story_id: int) -> Story:
    story = _story_query(db).filter(Story.id == story_id).first()
    if not story:
        raise HTTPException(status_code=404, detail="Histoire introuvable.")
    return story


def delete_story(db: Session, story_id: int, user: User):
    story = db.query(Story).filter(Story.id == story_id).first()
    if not story:
        raise HTTPException(status_code=404, detail="Histoire introuvable.")
    if story.author_id != user.id and user.role != "ADMIN":
        raise HTTPException(status_code=403, detail="Vous ne pouvez supprimer que vos propres histoires.")
    db.delete(story)
    db.commit()


def add_story_media(db: Session, story_id: int, type_media: str, nom_fichier: str) -> StoryMedia:
    media = StoryMedia(story_id=story_id, type=type_media, nom_fichier=nom_fichier)
    db.add(media)
    db.commit()
    db.refresh(media)
    return media


def toggle_like(db: Session, story_id: int, user_id: int) -> bool:
    if not db.query(Story).filter(Story.id == story_id).first():
        raise HTTPException(status_code=404, detail="Histoire introuvable.")

    existing = (
        db.query(StoryLike)
        .filter(StoryLike.story_id == story_id, StoryLike.user_id == user_id)
        .first()
    )
    if existing:
        db.delete(existing)
        db.commit()
        return False

    db.add(StoryLike(story_id=story_id, user_id=user_id))
    db.commit()
    return True


def add_comment(db: Session, story_id: int, user_id: int, contenu: str) -> StoryComment:
    if not db.query(Story).filter(Story.id == story_id).first():
        raise HTTPException(status_code=404, detail="Histoire introuvable.")
    comment = StoryComment(story_id=story_id, user_id=user_id, contenu=contenu)
    db.add(comment)
    db.commit()
    db.refresh(comment)
    return comment


def get_comments(db: Session, story_id: int):
    return (
        db.query(StoryComment)
        .options(joinedload(StoryComment.author))
        .filter(StoryComment.story_id == story_id)
        .order_by(StoryComment.created_at.asc())
        .all()
    )


def add_report(db: Session, story_id: int, user_id: int, raison: Optional[str]) -> StoryReport:
    if not db.query(Story).filter(Story.id == story_id).first():
        raise HTTPException(status_code=404, detail="Histoire introuvable.")
    report = StoryReport(story_id=story_id, user_id=user_id, raison=raison)
    db.add(report)
    db.commit()
    db.refresh(report)
    return report


def submit_certification_request(
    db: Session, user_id: int, type_professionnel: str,
    description: Optional[str], document_fichier: str,
) -> CertificationRequest:
    request = CertificationRequest(
        user_id=user_id,
        type_professionnel=type_professionnel,
        description=description,
        document_fichier=document_fichier,
        statut="EN_ATTENTE",
    )
    db.add(request)
    db.commit()
    db.refresh(request)
    return request


def get_my_certification_status(db: Session, user_id: int) -> Optional[CertificationRequest]:
    return (
        db.query(CertificationRequest)
        .filter(CertificationRequest.user_id == user_id)
        .order_by(CertificationRequest.created_at.desc())
        .first()
    )


def list_certification_requests(db: Session, statut: Optional[str] = None):
    query = db.query(CertificationRequest).options(joinedload(CertificationRequest.user))
    if statut:
        query = query.filter(CertificationRequest.statut == statut)
    return query.order_by(CertificationRequest.created_at.asc()).all()


def review_certification_request(db: Session, request_id: int, statut: str) -> CertificationRequest:
    request = db.query(CertificationRequest).filter(CertificationRequest.id == request_id).first()
    if not request:
        raise HTTPException(status_code=404, detail="Demande introuvable.")
    if request.statut != "EN_ATTENTE":
        raise HTTPException(status_code=400, detail="Cette demande a déjà été traitée.")

    request.statut = statut
    if statut == "APPROUVEE":
        user = db.query(User).filter(User.id == request.user_id).first()
        if user:
            user.certifie = True
            user.statut_auteur = "PROFESSIONNEL"
    db.commit()
    db.refresh(request)
    return request
