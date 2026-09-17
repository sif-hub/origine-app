# app/core/config.py

from pydantic import field_validator
from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional


class Settings(BaseSettings):
    # App
    APP_ENV: str = "development"
    APP_DEBUG: bool = True
    APP_URL: str = "http://localhost:8000"

    # Base de données
    # DATABASE_URL a priorité sur les champs DB_* ci-dessous : utilisé pour
    # pointer directement vers un service géré (ex. Neon Postgres en prod),
    # sans reconstruire l'URL à partir de composants MySQL.
    DATABASE_URL: str = ""
    DB_HOST: str = "127.0.0.1"
    DB_PORT: Optional[int] = 3306
    DB_NAME: str = "origine_db"
    DB_USER: str = "origine"
    DB_PASS: str = "Origine@2026"

    @field_validator("DB_PORT", mode="before")
    @classmethod
    def _empty_port_to_none(cls, v):
        # DB_PORT="" dans un .env SQLite (DB_HOST vide) ne doit pas
        # faire échouer la validation : il n'est de toute façon pas
        # utilisé quand DB_HOST est vide (voir _build_db_url).
        return None if v == "" else v

    # JWT
    JWT_SECRET: str = "insecure_default_change_me_in_production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TTL: int = 900        # 15 minutes
    JWT_REFRESH_TTL: int = 2592000   # 30 jours

    # IA
    OPENAI_API_KEY: str = ""
    CLAUDE_API_KEY: str = ""
    GEMINI_API_KEY: str = ""
    DEEPSEEK_API_KEY: str = ""
    AI_PROVIDER: str = "CLAUDE"

    # Upload
    UPLOAD_DIR: str = "storage/uploads"
    MAX_UPLOAD_SIZE: int = 5 * 1024 * 1024  # 5 Mo

    # Notifications Web Push (VAPID)
    VAPID_PUBLIC_KEY: str = ""
    VAPID_PRIVATE_KEY: str = ""
    VAPID_CLAIMS_EMAIL: str = "mailto:admin@origine.cm"

    # Stockage fichiers (Cloudinary) — si renseigné, remplace le disque local
    # pour les uploads (nécessaire en production sur un hébergeur sans disque
    # persistant, ex. Vercel).
    CLOUDINARY_CLOUD_NAME: str = ""
    CLOUDINARY_API_KEY: str = ""
    CLOUDINARY_API_SECRET: str = ""

    @property
    def IS_SQLITE(self) -> bool:
        return not self.DB_HOST

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
