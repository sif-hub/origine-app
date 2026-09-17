from urllib.parse import quote_plus
# app/core/database.py

from sqlalchemy import create_engine, BigInteger, Integer
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from .config import settings

# Clé primaire BigInteger, mais Integer sous SQLite : SQLite n'auto-incrémente
# nativement (alias ROWID) que les colonnes de type Integer ; utilisé pour les
# tests locaux sans MySQL (voir _build_db_url ci-dessous).
BigIntPK = BigInteger().with_variant(Integer, "sqlite")


def _build_db_url() -> str:
    """
    Construit l'URL de connexion selon la configuration :
    - Si DATABASE_URL est défini → utilisé tel quel (ex. Neon Postgres en prod)
    - Sinon si DB_HOST est vide → SQLite (pour les tests locaux sans base gérée)
    - Sinon → MySQL via PyMySQL
    """
    if settings.DATABASE_URL:
        url = settings.DATABASE_URL
        # Neon/Heroku-style fournissent parfois "postgres://" ; SQLAlchemy +
        # psycopg2 attendent le dialecte explicite "postgresql+psycopg2://".
        if url.startswith("postgres://"):
            url = "postgresql+psycopg2://" + url[len("postgres://"):]
        elif url.startswith("postgresql://"):
            url = "postgresql+psycopg2://" + url[len("postgresql://"):]
        return url
    if not settings.DB_HOST:
        return f"sqlite:///{settings.DB_NAME}"
    password = quote_plus(settings.DB_PASS)
    port = settings.DB_PORT or 3306
    return (
        f"mysql+pymysql://{settings.DB_USER}:{password}"
        f"@{settings.DB_HOST}:{port}/{settings.DB_NAME}"
        f"?charset=utf8mb4"
    )


DATABASE_URL = _build_db_url()

# SQLite nécessite check_same_thread=False
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(
    DATABASE_URL,
    connect_args=connect_args,
    pool_pre_ping=True,
    echo=settings.APP_DEBUG,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """Dépendance FastAPI : session DB injectée et fermée automatiquement."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

