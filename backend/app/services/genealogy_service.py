# app/services/genealogy_service.py

from sqlalchemy.orm import Session
from fastapi import HTTPException
from ..models.genealogy import Family, FamilyShare, Person, Relationship, PersonDocument, PersonMemory
from ..models.user import User
from typing import Optional


def create_family(db: Session, owner_id: int, nom: str,
                  visibilite: str = "PRIVE", description: Optional[str] = None) -> Family:
    family = Family(nom=nom, owner_id=owner_id,
                    visibilite=visibilite, description=description)
    db.add(family)
    db.commit()
    db.refresh(family)
    return family


def get_user_families(db: Session, owner_id: int):
    return db.query(Family).filter(Family.owner_id == owner_id).all()


def get_shared_families(db: Session, user_id: int):
    """Arbres partagés avec l'utilisateur : (famille, permission, propriétaire)."""
    rows = (
        db.query(Family, FamilyShare.permission, User)
        .join(FamilyShare, FamilyShare.family_id == Family.id)
        .join(User, User.id == Family.owner_id)
        .filter(FamilyShare.user_id == user_id)
        .all()
    )
    return rows


def _owned_family(db: Session, family_id: int, user_id: int) -> Family:
    family = db.query(Family).filter(Family.id == family_id).first()
    if not family:
        raise HTTPException(status_code=404, detail="Famille introuvable.")
    if family.owner_id != user_id:
        raise HTTPException(status_code=403, detail="Seul le propriétaire peut gérer le partage.")
    return family


def list_shares(db: Session, family_id: int, owner_id: int):
    _owned_family(db, family_id, owner_id)
    return (
        db.query(FamilyShare, User)
        .join(User, User.id == FamilyShare.user_id)
        .filter(FamilyShare.family_id == family_id)
        .order_by(FamilyShare.created_at.desc())
        .all()
    )


def add_share(db: Session, family_id: int, owner_id: int, user_id: int, permission: str) -> FamilyShare:
    family = _owned_family(db, family_id, owner_id)
    if user_id == owner_id:
        raise HTTPException(status_code=400, detail="Vous êtes déjà propriétaire de cet arbre.")
    if not db.query(User).filter(User.id == user_id, User.statut == "ACTIF").first():
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    share = db.query(FamilyShare).filter(
        FamilyShare.family_id == family_id, FamilyShare.user_id == user_id).first()
    if share:
        share.permission = permission
    else:
        share = FamilyShare(family_id=family_id, user_id=user_id, permission=permission)
        db.add(share)
    # Un arbre partagé ne peut plus rester "privé".
    if family.visibilite == "PRIVE":
        family.visibilite = "PARTAGE"
    db.commit()
    db.refresh(share)
    return share


def remove_share(db: Session, family_id: int, owner_id: int, user_id: int) -> None:
    _owned_family(db, family_id, owner_id)
    db.query(FamilyShare).filter(
        FamilyShare.family_id == family_id, FamilyShare.user_id == user_id).delete()
    db.commit()


def update_family(db: Session, family_id: int, data: dict) -> Family:
    family = db.query(Family).filter(Family.id == family_id).first()
    if not family:
        raise HTTPException(status_code=404, detail="Famille introuvable.")
    for field, value in data.items():
        setattr(family, field, value)
    db.commit()
    db.refresh(family)
    return family


def check_access(db: Session, family_id: int, user_id: int, edit_only: bool = False):
    family = db.query(Family).filter(Family.id == family_id).first()
    if not family:
        raise HTTPException(status_code=404, detail="Famille introuvable.")

    if family.owner_id == user_id:
        return family

    share = db.query(FamilyShare).filter(
        FamilyShare.family_id == family_id, FamilyShare.user_id == user_id).first()
    if share and (not edit_only or share.permission == "EDITION"):
        return family

    if family.visibilite == "PUBLIC" and not edit_only:
        return family

    raise HTTPException(status_code=403, detail="Accès refusé à cet arbre.")


def build_tree(db: Session, family_id: int) -> dict:
    persons = db.query(Person).filter(Person.family_id == family_id).all()
    nodes = [p.to_dict() for p in persons]

    edges = []
    person_ids = [p.id for p in persons]
    if person_ids:
        rels = db.query(Relationship).filter(
            Relationship.person_id.in_(person_ids)
        ).all()
        for r in rels:
            edges.append({
                "source": r.person_id,
                "target": r.related_person_id,
                "type":   r.type_relation,
            })

    return {"nodes": nodes, "edges": edges}


def build_timeline(db: Session, family_id: int) -> list:
    persons = db.query(Person).filter(Person.family_id == family_id).all()
    events  = []

    for p in persons:
        if p.date_naissance:
            events.append({
                "type":  "NAISSANCE",
                "date":  str(p.date_naissance),
                "titre": f"Naissance de {p.prenom or ''} {p.nom}".strip(),
            })
        if p.date_deces:
            events.append({
                "type":  "DECES",
                "date":  str(p.date_deces),
                "titre": f"Décès de {p.prenom or ''} {p.nom}".strip(),
            })

    return sorted(events, key=lambda e: e["date"])


def add_person(db: Session, data: dict, created_by: int) -> Person:
    person = Person(
        family_id=data.get("family_id"),
        nom=data["nom"],
        prenom=data.get("prenom"),
        sexe=data.get("sexe", "INCONNU"),
        date_naissance=data.get("date_naissance"),
        date_deces=data.get("date_deces"),
        vivant=0 if data.get("date_deces") else 1,
        notes=data.get("notes"),
        photo=data.get("photo"),
        lieu_naissance=data.get("lieu_naissance"),
        village_origine=data.get("village_origine"),
        nationalite=data.get("nationalite") or "Camerounais(e)",
        profession=data.get("profession"),
        nom_pere_texte=data.get("nom_pere_texte"),
        nom_mere_texte=data.get("nom_mere_texte"),
        created_by=created_by,
    )
    db.add(person)
    db.commit()
    db.refresh(person)
    return person


def update_person_privacy(db: Session, person_id: int, data: dict) -> Person:
    person = db.query(Person).filter(Person.id == person_id).first()
    if not person:
        raise HTTPException(status_code=404, detail="Personne introuvable.")
    for field, value in data.items():
        setattr(person, field, value)
    db.commit()
    db.refresh(person)
    return person


def add_person_document(db: Session, person_id: int, type_document: str,
                        nom_fichier: str, uploaded_by: int) -> PersonDocument:
    if not db.query(Person).filter(Person.id == person_id).first():
        raise HTTPException(status_code=404, detail="Personne introuvable.")
    doc = PersonDocument(
        person_id=person_id, type_document=type_document,
        nom_fichier=nom_fichier, uploaded_by=uploaded_by,
    )
    db.add(doc)
    db.commit()
    db.refresh(doc)
    return doc


def get_person_documents(db: Session, person_id: int):
    return db.query(PersonDocument).filter(PersonDocument.person_id == person_id).all()


def delete_person_document(db: Session, person_id: int, doc_id: int):
    doc = db.query(PersonDocument).filter(
        PersonDocument.id == doc_id, PersonDocument.person_id == person_id
    ).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Document introuvable.")
    db.delete(doc)
    db.commit()


def add_person_memory(db: Session, person_id: int, type_memory: str,
                      nom_fichier: str, uploaded_by: int) -> PersonMemory:
    if not db.query(Person).filter(Person.id == person_id).first():
        raise HTTPException(status_code=404, detail="Personne introuvable.")
    memory = PersonMemory(
        person_id=person_id, type=type_memory,
        nom_fichier=nom_fichier, uploaded_by=uploaded_by,
    )
    db.add(memory)
    db.commit()
    db.refresh(memory)
    return memory


def get_person_memories(db: Session, person_id: int):
    return db.query(PersonMemory).filter(PersonMemory.person_id == person_id).all()


def delete_person_memory(db: Session, person_id: int, memory_id: int):
    memory = db.query(PersonMemory).filter(
        PersonMemory.id == memory_id, PersonMemory.person_id == person_id
    ).first()
    if not memory:
        raise HTTPException(status_code=404, detail="Souvenir introuvable.")
    db.delete(memory)
    db.commit()


def get_family_documents(db: Session, family_id: int):
    return (
        db.query(PersonDocument)
        .join(Person, PersonDocument.person_id == Person.id)
        .filter(Person.family_id == family_id)
        .all()
    )


def get_family_memories(db: Session, family_id: int):
    return (
        db.query(PersonMemory)
        .join(Person, PersonMemory.person_id == Person.id)
        .filter(Person.family_id == family_id)
        .all()
    )


def link_persons(db: Session, person_id: int, related_id: int,
                 type_relation: str, date_debut=None, date_fin=None):
    if person_id == related_id:
        raise HTTPException(status_code=400, detail="Une personne ne peut pas être liée à elle-même.")

    # Vérifie les deux personnes existent
    for pid in (person_id, related_id):
        if not db.query(Person).filter(Person.id == pid).first():
            raise HTTPException(status_code=404, detail=f"Personne {pid} introuvable.")

    _upsert_relation(db, person_id, related_id, type_relation, date_debut, date_fin)

    # Relation inverse automatique
    inverse = {
        "PERE": "ENFANT", "MERE": "ENFANT",
        "CONJOINT": "CONJOINT", "FRERE_SOEUR": "FRERE_SOEUR",
        "ENFANT": _guess_parent_type(db, related_id),
    }.get(type_relation)

    if inverse:
        _upsert_relation(db, related_id, person_id, inverse, date_debut, date_fin)

    db.commit()


def _upsert_relation(db, person_id, related_id, type_rel, date_debut, date_fin):
    existing = (
        db.query(Relationship)
        .filter(
            Relationship.person_id == person_id,
            Relationship.related_person_id == related_id,
            Relationship.type_relation == type_rel,
        )
        .first()
    )
    if not existing:
        db.add(Relationship(
            person_id=person_id,
            related_person_id=related_id,
            type_relation=type_rel,
            date_debut=date_debut,
            date_fin=date_fin,
        ))


def _guess_parent_type(db: Session, person_id: int) -> str:
    person = db.query(Person).filter(Person.id == person_id).first()
    return "MERE" if person and person.sexe == "F" else "PERE"


def merge_families(db: Session, source_id: int, target_id: int):
    db.query(Person).filter(Person.family_id == source_id).update(
        {"family_id": target_id}
    )
    db.commit()
