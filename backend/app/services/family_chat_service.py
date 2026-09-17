# app/services/family_chat_service.py

from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException
from ..models.family_chat import FamilyGroup, FamilyGroupMember, FamilyMessage
from ..models.user import User
from typing import Optional, List


def _is_member(db: Session, group_id: int, user_id: int) -> bool:
    return (
        db.query(FamilyGroupMember)
        .filter(FamilyGroupMember.group_id == group_id, FamilyGroupMember.user_id == user_id)
        .first()
        is not None
    )


def check_membership(db: Session, group_id: int, user_id: int) -> FamilyGroup:
    group = db.query(FamilyGroup).filter(FamilyGroup.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Groupe introuvable.")
    if not _is_member(db, group_id, user_id):
        raise HTTPException(status_code=403, detail="Vous ne faites pas partie de ce groupe.")
    return group


def create_group(db: Session, nom: str, creator_id: int, member_ids: List[int]) -> FamilyGroup:
    group = FamilyGroup(nom=nom, created_by=creator_id)
    db.add(group)
    db.commit()
    db.refresh(group)

    all_member_ids = {creator_id, *member_ids}
    for uid in all_member_ids:
        if db.query(User).filter(User.id == uid).first():
            db.add(FamilyGroupMember(group_id=group.id, user_id=uid))
    db.commit()
    db.refresh(group)
    return group


def get_my_groups(db: Session, user_id: int):
    memberships = (
        db.query(FamilyGroupMember)
        .options(joinedload(FamilyGroupMember.group).joinedload(FamilyGroup.members))
        .filter(FamilyGroupMember.user_id == user_id)
        .all()
    )
    result = []
    for m in memberships:
        last_message = (
            db.query(FamilyMessage)
            .filter(FamilyMessage.group_id == m.group_id)
            .order_by(FamilyMessage.created_at.desc())
            .first()
        )
        result.append((m.group, last_message))
    result.sort(key=lambda pair: pair[1].created_at if pair[1] else pair[0].created_at, reverse=True)
    return result


def add_member(db: Session, group_id: int, user_id: int, requester_id: int):
    check_membership(db, group_id, requester_id)
    if not db.query(User).filter(User.id == user_id).first():
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    if _is_member(db, group_id, user_id):
        return
    db.add(FamilyGroupMember(group_id=group_id, user_id=user_id))
    db.commit()


def list_members(db: Session, group_id: int, requester_id: int):
    check_membership(db, group_id, requester_id)
    return (
        db.query(FamilyGroupMember)
        .options(joinedload(FamilyGroupMember.group))
        .filter(FamilyGroupMember.group_id == group_id)
        .all()
    )


def send_message(
    db: Session, group_id: int, sender_id: int,
    contenu: Optional[str], type_message: str = "TEXT", nom_fichier: Optional[str] = None,
) -> FamilyMessage:
    check_membership(db, group_id, sender_id)
    message = FamilyMessage(
        group_id=group_id, sender_id=sender_id,
        contenu=contenu, type_message=type_message, nom_fichier=nom_fichier,
    )
    db.add(message)
    db.commit()
    db.refresh(message)
    return message


def get_messages(db: Session, group_id: int, requester_id: int, limit: int = 50, offset: int = 0):
    check_membership(db, group_id, requester_id)
    messages = (
        db.query(FamilyMessage)
        .options(joinedload(FamilyMessage.sender))
        .filter(FamilyMessage.group_id == group_id)
        .order_by(FamilyMessage.created_at.desc())
        .offset(offset).limit(limit)
        .all()
    )
    return list(reversed(messages))


def search_users(db: Session, query: str, exclude_user_id: int, limit: int = 20):
    like = f"%{query}%"
    return (
        db.query(User)
        .filter(
            User.id != exclude_user_id,
            (User.nom.ilike(like)) | (User.prenom.ilike(like)) | (User.email.ilike(like)),
        )
        .limit(limit)
        .all()
    )
