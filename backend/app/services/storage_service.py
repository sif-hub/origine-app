# app/services/storage_service.py
#
# Point d'entrée unique pour l'enregistrement des fichiers uploadés (avatars,
# médias d'histoires, documents, pièces jointes de chat...). Bascule
# automatiquement entre deux backends selon la configuration :
#   - Cloudinary, si CLOUDINARY_* est renseigné (production, notamment sur un
#     hébergeur sans disque persistant comme Vercel) → renvoie une URL
#     absolue, stockée telle quelle en base.
#   - disque local sinon (dev) → renvoie un simple nom de fichier, servi
#     ensuite via /uploads/<subfolder>/<filename>.

import os
import secrets

from fastapi import HTTPException, UploadFile

from ..core.config import settings

_cloudinary_configured = bool(
    settings.CLOUDINARY_CLOUD_NAME and settings.CLOUDINARY_API_KEY and settings.CLOUDINARY_API_SECRET
)

if _cloudinary_configured:
    import cloudinary
    import cloudinary.uploader

    cloudinary.config(
        cloud_name=settings.CLOUDINARY_CLOUD_NAME,
        api_key=settings.CLOUDINARY_API_KEY,
        api_secret=settings.CLOUDINARY_API_SECRET,
        secure=True,
    )


async def save_upload(upload: UploadFile, subfolder: str) -> str:
    content = await upload.read()
    if len(content) > settings.MAX_UPLOAD_SIZE:
        raise HTTPException(status_code=400, detail="Fichier trop volumineux (max 5 Mo).")

    ext = upload.filename.rsplit(".", 1)[-1].lower() if upload.filename and "." in upload.filename else "bin"
    filename = f"{secrets.token_hex(16)}.{ext}"

    if _cloudinary_configured:
        result = cloudinary.uploader.upload(
            content,
            public_id=filename.rsplit(".", 1)[0],
            folder=subfolder,
            resource_type="auto",
        )
        return result["secure_url"]

    dest_dir = os.path.join(settings.UPLOAD_DIR, subfolder)
    os.makedirs(dest_dir, exist_ok=True)
    with open(os.path.join(dest_dir, filename), "wb") as f:
        f.write(content)
    return filename
