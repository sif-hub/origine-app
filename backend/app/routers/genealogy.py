# app/routers/genealogy.py

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from ..core.database import get_db
from ..core.security import get_current_user
from ..schemas.genealogy import (
    FamilyCreate, FamilyUpdate, PersonCreate, PersonUpdate, PersonPrivacyUpdate,
    LinkRequest, MergeFamiliesRequest, ShareFamilyRequest
)
from ..services import genealogy_service as svc
from ..services import storage_service
from ..services.storage_service import save_upload as _save_upload
from ..models.genealogy import Person

router = APIRouter(tags=["Généalogie"])

ALLOWED_DOCUMENT_MIME = {"application/pdf", "image/jpeg", "image/png"}
ALLOWED_MEMORY_MIME = {
    "image/jpeg", "image/png", "image/webp",
    "video/mp4", "video/quicktime",
    "audio/mpeg", "audio/mp4", "audio/wav", "audio/x-m4a",
}


def _guard_person_edit(db, person, user):
    """Seul le propriétaire (ou un membre avec droit d'édition) modifie un arbre."""
    if person.family_id is None:
        if person.created_by != user.id:
            raise HTTPException(status_code=403, detail="Accès refusé à cette personne.")
    else:
        svc.check_access(db, person.family_id, user.id, edit_only=True)


def _person_or_404(db, person_id, detail="Personne introuvable."):
    person = db.query(Person).filter(Person.id == person_id).first()
    if not person:
        raise HTTPException(status_code=404, detail=detail)
    return person


# ── FAMILLES ────────────────────────────────────────────────────────────

@router.post("/families", status_code=201)
def create_family(body: FamilyCreate, db=Depends(get_db), user=Depends(get_current_user)):
    family = svc.create_family(db, user.id, body.nom, body.visibilite, body.description)
    return {"success": True, "message": "Famille créée.", "data": {"family": family.to_dict()}}


@router.get("/families")
def list_families(db=Depends(get_db), user=Depends(get_current_user)):
    families = [f.to_dict() for f in svc.get_user_families(db, user.id)]
    for family, permission, owner in svc.get_shared_families(db, user.id):
        d = family.to_dict()
        d.update({
            "shared": True,
            "permission": permission,
            "owner_nom": f"{owner.prenom or ''} {owner.nom}".strip(),
        })
        families.append(d)
    return {"success": True, "data": {"families": families}}


# ── PARTAGE D'UN ARBRE AVEC UN MEMBRE ───────────────────────────────────

@router.get("/families/{family_id}/shares")
def list_family_shares(family_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    rows = svc.list_shares(db, family_id, user.id)
    return {"success": True, "data": {"shares": [
        {"user": u.to_public_dict(), "permission": share.permission}
        for share, u in rows
    ]}}


@router.post("/families/{family_id}/shares", status_code=201)
def share_family(family_id: int, body: ShareFamilyRequest, db=Depends(get_db), user=Depends(get_current_user)):
    share = svc.add_share(db, family_id, user.id, body.user_id, body.permission)
    return {"success": True, "message": "Arbre partagé.", "data": {"permission": share.permission}}


@router.delete("/families/{family_id}/shares/{user_id}", status_code=204)
def unshare_family(family_id: int, user_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    svc.remove_share(db, family_id, user.id, user_id)


@router.get("/families/{family_id}/tree")
def get_tree(family_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    svc.check_access(db, family_id, user.id)
    tree = svc.build_tree(db, family_id)
    return {"success": True, "data": {"tree": tree}}


@router.get("/families/{family_id}/timeline")
def get_timeline(family_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    svc.check_access(db, family_id, user.id)
    timeline = svc.build_timeline(db, family_id)
    return {"success": True, "data": {"timeline": timeline}}


@router.post("/families/merge")
def merge(body: MergeFamiliesRequest, db=Depends(get_db), user=Depends(get_current_user)):
    svc.check_access(db, body.source_family_id, user.id, edit_only=True)
    svc.check_access(db, body.target_family_id, user.id, edit_only=True)
    svc.merge_families(db, body.source_family_id, body.target_family_id)
    return {"success": True, "message": "Familles fusionnées avec succès."}


@router.put("/families/{family_id}")
def update_family(family_id: int, body: FamilyUpdate, db=Depends(get_db), user=Depends(get_current_user)):
    svc.check_access(db, family_id, user.id, edit_only=True)
    family = svc.update_family(db, family_id, body.model_dump(exclude_none=True))
    return {"success": True, "message": "Famille mise à jour.", "data": {"family": family.to_dict()}}


@router.get("/families/{family_id}/documents")
def list_family_documents(family_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    svc.check_access(db, family_id, user.id)
    docs = svc.get_family_documents(db, family_id)
    return {"success": True, "data": {"documents": [d.to_dict() for d in docs]}}


@router.get("/families/{family_id}/memories")
def list_family_memories(family_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    svc.check_access(db, family_id, user.id)
    memories = svc.get_family_memories(db, family_id)
    return {"success": True, "data": {"memories": [m.to_dict() for m in memories]}}


# ── PERSONNES ───────────────────────────────────────────────────────────

@router.post("/persons", status_code=201)
def create_person(body: PersonCreate, db=Depends(get_db), user=Depends(get_current_user)):
    if body.family_id is not None:
        svc.check_access(db, body.family_id, user.id, edit_only=True)
    person = svc.add_person(db, body.model_dump(), user.id)
    return {"success": True, "message": "Personne ajoutée.", "data": {"person": person.to_dict()}}


@router.get("/persons/{person_id}")
def get_person(person_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    person = db.query(Person).filter(Person.id == person_id).first()
    if not person:
        raise HTTPException(status_code=404, detail="Personne introuvable.")
    return {"success": True, "data": {"person": person.to_dict()}}


@router.put("/persons/{person_id}")
def update_person(person_id: int, body: PersonUpdate, db=Depends(get_db), user=Depends(get_current_user)):
    person = _person_or_404(db, person_id)
    _guard_person_edit(db, person, user)

    for field, value in body.model_dump(exclude_none=True).items():
        setattr(person, field, value)
    if body.date_deces is not None:
        person.vivant = 0
    db.commit()
    db.refresh(person)
    return {"success": True, "data": {"person": person.to_dict()}}


@router.delete("/persons/{person_id}", status_code=204)
def delete_person(person_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    person = _person_or_404(db, person_id)
    _guard_person_edit(db, person, user)
    db.delete(person)
    db.commit()


ALLOWED_PHOTO_MIME = {"image/jpeg", "image/png", "image/webp"}


@router.post("/persons/{person_id}/photo")
async def upload_person_photo(
    person_id: int,
    photo: UploadFile = File(...),
    db=Depends(get_db), user=Depends(get_current_user),
):
    person = _person_or_404(db, person_id)
    _guard_person_edit(db, person, user)
    if photo.content_type not in ALLOWED_PHOTO_MIME:
        raise HTTPException(status_code=400, detail="Format non autorisé. Utilisez JPEG, PNG ou WEBP.")
    person.photo = await _save_upload(photo, "person_photos")
    db.commit()
    db.refresh(person)
    return {"success": True, "data": {"person": person.to_dict()}}


@router.post("/persons/{person_id}/parent", status_code=201)
def add_parent(person_id: int, body: PersonCreate, db=Depends(get_db), user=Depends(get_current_user)):
    child = _person_or_404(db, person_id, "Enfant introuvable.")
    _guard_person_edit(db, child, user)

    data = body.model_dump()
    data["family_id"] = data.get("family_id") or child.family_id
    parent = svc.add_person(db, data, user.id)

    type_rel = "MERE" if parent.sexe == "F" else "PERE"
    svc.link_persons(db, parent.id, person_id, type_rel)
    return {"success": True, "data": {"person": parent.to_dict()}}


@router.post("/persons/{person_id}/child", status_code=201)
def add_child(person_id: int, body: PersonCreate, db=Depends(get_db), user=Depends(get_current_user)):
    parent = _person_or_404(db, person_id, "Parent introuvable.")
    _guard_person_edit(db, parent, user)

    data = body.model_dump()
    data["family_id"] = data.get("family_id") or parent.family_id
    child = svc.add_person(db, data, user.id)
    svc.link_persons(db, person_id, child.id, "ENFANT")
    return {"success": True, "data": {"person": child.to_dict()}}


@router.post("/persons/{person_id}/spouse", status_code=201)
def add_spouse(person_id: int, body: PersonCreate, db=Depends(get_db), user=Depends(get_current_user)):
    person = _person_or_404(db, person_id)
    _guard_person_edit(db, person, user)

    data = body.model_dump()
    data["family_id"] = data.get("family_id") or person.family_id
    spouse = svc.add_person(db, data, user.id)
    svc.link_persons(db, person_id, spouse.id, "CONJOINT")
    return {"success": True, "data": {"person": spouse.to_dict()}}


@router.post("/persons/{person_id}/link")
def link(person_id: int, body: LinkRequest, db=Depends(get_db), user=Depends(get_current_user)):
    _guard_person_edit(db, _person_or_404(db, person_id), user)
    svc.link_persons(db, person_id, body.related_person_id, body.type, body.date_debut, body.date_fin)
    return {"success": True, "message": "Lien créé avec succès."}


@router.put("/persons/{person_id}/privacy")
def update_person_privacy(person_id: int, body: PersonPrivacyUpdate,
                          db=Depends(get_db), user=Depends(get_current_user)):
    _guard_person_edit(db, _person_or_404(db, person_id), user)
    person = svc.update_person_privacy(db, person_id, body.model_dump(exclude_none=True))
    return {"success": True, "message": "Confidentialité mise à jour.", "data": {"person": person.to_dict()}}


# ── DOCUMENTS ───────────────────────────────────────────────────────────

@router.post("/persons/{person_id}/documents", status_code=201)
async def upload_person_document(
    person_id: int,
    type_document: str = Form(..., pattern="^(ACTE_NAISSANCE|ACTE_MARIAGE|ACTE_DECES|AUTRE)$"),
    fichier: UploadFile = File(...),
    db=Depends(get_db), user=Depends(get_current_user),
):
    if fichier.content_type not in ALLOWED_DOCUMENT_MIME:
        raise HTTPException(status_code=400, detail="Format non autorisé. Utilisez PDF, JPEG ou PNG.")

    filename = await _save_upload(fichier, "person_documents")
    doc = svc.add_person_document(db, person_id, type_document, filename, user.id)
    return {"success": True, "message": "Document ajouté.", "data": {"document": doc.to_dict()}}


@router.get("/persons/{person_id}/documents")
def list_person_documents(person_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    docs = svc.get_person_documents(db, person_id)
    return {"success": True, "data": {"documents": [d.to_dict() for d in docs]}}


@router.delete("/persons/{person_id}/documents/{doc_id}", status_code=204)
def delete_person_document(person_id: int, doc_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    svc.delete_person_document(db, person_id, doc_id)


# ── SOUVENIRS ───────────────────────────────────────────────────────────

@router.post("/persons/{person_id}/memories", status_code=201)
async def upload_person_memory(
    person_id: int,
    type: str = Form(..., pattern="^(PHOTO|VIDEO|AUDIO)$"),
    fichier: Optional[UploadFile] = File(None),
    url: Optional[str] = Form(None),
    db=Depends(get_db), user=Depends(get_current_user),
):
    _guard_person_edit(db, _person_or_404(db, person_id), user)

    if url:
        # Fichier déjà envoyé directement à Cloudinary par l'application.
        if not storage_service.is_own_cloudinary_url(url):
            raise HTTPException(status_code=400, detail="Média envoyé invalide.")
        filename = url
    elif fichier is not None:
        if fichier.content_type not in ALLOWED_MEMORY_MIME:
            raise HTTPException(status_code=400, detail="Format de fichier non autorisé.")
        filename = await _save_upload(fichier, "person_memories")
    else:
        raise HTTPException(status_code=400, detail="Aucun fichier fourni.")
    memory = svc.add_person_memory(db, person_id, type, filename, user.id)
    return {"success": True, "message": "Souvenir ajouté.", "data": {"memory": memory.to_dict()}}


@router.get("/persons/{person_id}/memories")
def list_person_memories(person_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    memories = svc.get_person_memories(db, person_id)
    return {"success": True, "data": {"memories": [m.to_dict() for m in memories]}}


@router.delete("/persons/{person_id}/memories/{memory_id}", status_code=204)
def delete_person_memory(person_id: int, memory_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    svc.delete_person_memory(db, person_id, memory_id)
