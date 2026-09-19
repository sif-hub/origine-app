# app/routers/stories.py

from datetime import date
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from pydantic import ValidationError
from pydantic import BaseModel
from ..core.database import get_db
from ..core.security import get_current_user, require_admin
from ..schemas.story import StoryCreate, CommentCreate, ReportCreate, CertificationRequestCreate
from ..services import story_service as svc
from ..services import storage_service
from ..services.storage_service import save_upload as _save_upload

router = APIRouter(tags=["Histoires"])

ALLOWED_MEDIA_MIME = {
    "image/jpeg", "image/png", "image/webp",
    "video/mp4", "video/quicktime",
    "audio/mpeg", "audio/mp4", "audio/wav", "audio/x-m4a",
}
ALLOWED_DOCUMENT_MIME = {"application/pdf", "image/jpeg", "image/png"}


# ── HISTOIRES ──────────────────────────────────────────────────────────

@router.post("/stories", status_code=201)
async def create_story(
    titre: str = Form(...),
    description: str = Form(...),
    date_histoire: Optional[str] = Form(None),
    region: Optional[str] = Form(None),
    village: Optional[str] = Form(None),
    categorie: str = Form("AUTRE"),
    mots_cles: Optional[str] = Form(None),
    source: Optional[str] = Form(None),
    autoriser_tts: bool = Form(True),
    medias: List[UploadFile] = File(default=[]),
    media_types: List[str] = Form(default=[]),
    media_urls: List[str] = Form(default=[]),
    media_url_types: List[str] = Form(default=[]),
    db=Depends(get_db), user=Depends(get_current_user),
):
    try:
        body = StoryCreate(
            titre=titre, description=description, date_histoire=date_histoire or None,
            region=region, village=village, categorie=categorie,
            mots_cles=mots_cles, source=source, autoriser_tts=autoriser_tts,
        )
    except ValidationError as e:
        raise HTTPException(status_code=422, detail=e.errors())

    if medias and len(medias) != len(media_types):
        raise HTTPException(status_code=400, detail="media_types doit correspondre à medias.")

    if len(media_urls) != len(media_url_types):
        raise HTTPException(status_code=400, detail="media_url_types doit correspondre à media_urls.")
    for url, media_type in zip(media_urls, media_url_types):
        if media_type not in ("PHOTO", "VIDEO", "AUDIO") or not storage_service.is_own_cloudinary_url(url):
            raise HTTPException(status_code=400, detail="Média envoyé invalide.")

    story = svc.create_story(db, body.model_dump(), user.id)

    for url, media_type in zip(media_urls, media_url_types):
        svc.add_story_media(db, story.id, media_type, url)

    for media, media_type in zip(medias, media_types):
        if media_type not in ("PHOTO", "VIDEO", "AUDIO"):
            raise HTTPException(status_code=400, detail=f"Type de média invalide : {media_type}")
        if media.content_type not in ALLOWED_MEDIA_MIME:
            raise HTTPException(status_code=400, detail="Format de média non autorisé.")
        filename = await _save_upload(media, "story_media")
        svc.add_story_media(db, story.id, media_type, filename)

    story = svc.get_story(db, story.id)
    return {"success": True, "message": "Histoire publiée.", "data": {"story": story.to_dict(user.id)}}


@router.get("/stories")
def list_stories(limit: int = 20, offset: int = 0, q: Optional[str] = None,
                 db=Depends(get_db), user=Depends(get_current_user)):
    stories = svc.get_feed(db, limit=limit, offset=offset, q=q)
    return {"success": True, "data": {"stories": [s.to_dict(user.id) for s in stories]}}


@router.get("/stories/{story_id}")
def get_story(story_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    story = svc.get_story(db, story_id)
    return {"success": True, "data": {"story": story.to_dict(user.id)}}


@router.delete("/stories/{story_id}", status_code=204)
def delete_story(story_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    svc.delete_story(db, story_id, user)


# ── LIKES ───────────────────────────────────────────────────────────────

@router.post("/stories/{story_id}/like")
def like_story(story_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    liked = svc.toggle_like(db, story_id, user.id)
    return {"success": True, "data": {"liked": liked}}


# ── COMMENTAIRES ────────────────────────────────────────────────────────

@router.post("/stories/{story_id}/comments", status_code=201)
def add_comment(story_id: int, body: CommentCreate, db=Depends(get_db), user=Depends(get_current_user)):
    comment = svc.add_comment(db, story_id, user.id, body.contenu)
    return {"success": True, "data": {"comment": comment.to_dict()}}


@router.get("/stories/{story_id}/comments")
def list_comments(story_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    comments = svc.get_comments(db, story_id)
    return {"success": True, "data": {"comments": [c.to_dict() for c in comments]}}


# ── SIGNALEMENT ─────────────────────────────────────────────────────────

@router.post("/stories/{story_id}/report", status_code=201)
def report_story(story_id: int, body: ReportCreate, db=Depends(get_db), user=Depends(get_current_user)):
    svc.add_report(db, story_id, user.id, body.raison)
    return {"success": True, "message": "Signalement envoyé."}


# ── CERTIFICATION ───────────────────────────────────────────────────────

@router.post("/certification-requests", status_code=201)
async def submit_certification_request(
    type_professionnel: str = Form(...),
    description: Optional[str] = Form(None),
    document: UploadFile = File(...),
    db=Depends(get_db), user=Depends(get_current_user),
):
    try:
        body = CertificationRequestCreate(type_professionnel=type_professionnel, description=description)
    except ValidationError as e:
        raise HTTPException(status_code=422, detail=e.errors())

    if document.content_type not in ALLOWED_DOCUMENT_MIME:
        raise HTTPException(status_code=400, detail="Format non autorisé. Utilisez PDF, JPEG ou PNG.")

    filename = await _save_upload(document, "certification_documents")
    request = svc.submit_certification_request(
        db, user.id, body.type_professionnel, body.description, filename
    )
    return {"success": True, "message": "Demande de certification envoyée.", "data": {"request": request.to_dict()}}


@router.get("/certification-requests/me")
def my_certification_status(db=Depends(get_db), user=Depends(get_current_user)):
    request = svc.get_my_certification_status(db, user.id)
    return {"success": True, "data": {"request": request.to_dict() if request else None}}


# ── ADMINISTRATION (validation des certifications) ──────────────────────

class ReviewCertificationRequest(BaseModel):
    statut: str


@router.get("/admin/certification-requests")
def admin_list_certification_requests(
    statut: Optional[str] = None, db=Depends(get_db), admin=Depends(require_admin),
):
    requests = svc.list_certification_requests(db, statut=statut)
    return {"success": True, "data": {"requests": [r.to_dict() for r in requests]}}


@router.put("/admin/certification-requests/{request_id}")
def admin_review_certification_request(
    request_id: int, body: ReviewCertificationRequest,
    db=Depends(get_db), admin=Depends(require_admin),
):
    if body.statut not in ("APPROUVEE", "REJETEE"):
        raise HTTPException(status_code=400, detail="Statut invalide.")
    request = svc.review_certification_request(db, request_id, body.statut)
    message = "Certification approuvée." if body.statut == "APPROUVEE" else "Demande rejetée."
    return {"success": True, "message": message, "data": {"request": request.to_dict()}}
