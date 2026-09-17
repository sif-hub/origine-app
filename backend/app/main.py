# app/main.py

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from .core.database import engine, SessionLocal, Base
from .core.config import settings
from .core.security import hash_password

# Import centralisé de tous les modèles (nécessaire pour create_all)
from .models import User, RefreshToken, LoginAttempt          # noqa
from .models import Tribe, Clan, Family, FamilyShare          # noqa
from .models import Person, Relationship                       # noqa
from .models import PersonDocument, PersonMemory               # noqa
from .models import AIProvider, AILog                         # noqa
from .models import Story, StoryMedia, StoryLike, StoryComment, StoryReport, CertificationRequest  # noqa
from .models import FamilyGroup, FamilyGroupMember, FamilyMessage  # noqa
from .models import FamilyEvent                               # noqa
from .models import PushSubscription                           # noqa

from .routers import auth, profile, genealogy, ai, stories, family_chat, events, push


def _init_db():
    """Crée toutes les tables et insère les données par défaut."""
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        _seed_ai_providers(db)
        _seed_default_users(db)
    finally:
        db.close()


def _seed_ai_providers(db):
    if db.query(AIProvider).count() > 0:
        return
    db.add_all([
        AIProvider(nom="CLAUDE",   actif=1, config_json={"model": "claude-sonnet-4-6"}),
        AIProvider(nom="OPENAI",   actif=1, config_json={"model": "gpt-4o"}),
        AIProvider(nom="GEMINI",   actif=0, config_json={"model": "gemini-3.6-flash"}),
        AIProvider(nom="DEEPSEEK", actif=0, config_json={"model": "deepseek-chat"}),
    ])
    db.commit()


def _seed_default_users(db):
    """
    Comptes par défaut créés au premier démarrage :
      admin@origine.cm  /  Admin1234!   (ADMIN)
      jean@origine.cm   /  Test1234!    (UTILISATEUR)
    """
    if db.query(User).count() > 0:
        return

    db.add_all([
        User(
            nom="Admin", prenom="ORIGINE",
            email="admin@origine.cm",
            telephone="+237600000000",
            sexe="M",
            mot_de_passe_hash=hash_password("Admin1234!"),
            role="ADMIN",
            email_verifie=1, statut="ACTIF",
            biographie="Administrateur de la plateforme ORIGINE.",
            village_origine="Yaoundé", region="Centre",
            profession="Administrateur",
        ),
        User(
            nom="Mbarga", prenom="Jean",
            email="jean@origine.cm",
            telephone="+237677123456",
            sexe="M",
            mot_de_passe_hash=hash_password("Test1234!"),
            role="UTILISATEUR",
            email_verifie=1, statut="ACTIF",
            biographie="Passionné de généalogie camerounaise.",
            village_origine="Bafoussam", region="Ouest",
            profession="Ingénieur",
        ),
    ])
    db.commit()
    print("\n✅  Comptes par défaut créés :")
    print("    admin@origine.cm  →  Admin1234!")
    print("    jean@origine.cm   →  Test1234!\n")


# Exécuté à l'import du module plutôt que dans le lifespan ASGI : garantit
# que l'initialisation tourne bien sur les runtimes serverless (ex. Vercel)
# qui n'appellent pas toujours fidèlement les événements de lifespan, en plus
# du cas normal (uvicorn), où l'import n'a de toute façon lieu qu'une fois.
_init_db()

# Dossiers d'upload locaux : uniquement pertinents quand Cloudinary n'est pas
# configuré. Sur un hébergeur sans disque persistant (ex. Vercel), le disque
# de déploiement est en lecture seule — y écrire ferait planter l'import du
# module ; dans ce cas, le stockage passe entièrement par Cloudinary (voir
# services/storage_service.py) et ces dossiers ne servent à rien.
if not (settings.CLOUDINARY_CLOUD_NAME and settings.CLOUDINARY_API_KEY and settings.CLOUDINARY_API_SECRET):
    for _subfolder in (
        "avatars", "person_documents", "person_memories",
        "story_media", "certification_documents", "family_messages",
    ):
        os.makedirs(os.path.join(settings.UPLOAD_DIR, _subfolder), exist_ok=True)


app = FastAPI(
    title="ORIGINE API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

if os.path.exists(settings.UPLOAD_DIR):
    app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")


app.include_router(auth.router, prefix="/api")
app.include_router(profile.router, prefix="/api")
app.include_router(genealogy.router, prefix="/api")
app.include_router(ai.router, prefix="/api")
app.include_router(stories.router, prefix="/api")
app.include_router(family_chat.router, prefix="/api")
app.include_router(events.router, prefix="/api")
app.include_router(push.router, prefix="/api")

