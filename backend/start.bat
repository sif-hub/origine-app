@echo off
REM start.bat - Lance l'API ORIGINE sous Windows

echo.
echo  ╔═══════════════════════════════════╗
echo  ║        ORIGINE API — FastAPI      ║
echo  ╚═══════════════════════════════════╝
echo.

REM Copier .env si absent
if not exist ".env" (
    echo [WARN] .env absent, copie de .env.example...
    copy .env.example .env
    echo Editez .env avec vos identifiants MySQL puis relancez.
    pause
    exit /b 1
)

REM Créer venv si absent
if not exist "venv" (
    echo Creation de l'environnement virtuel...
    python -m venv venv
)

REM Activer et installer
call venv\Scripts\activate.bat
echo Installation des dependances...
pip install -r requirements.txt -q

REM Créer dossier uploads
if not exist "storage\uploads\avatars" mkdir storage\uploads\avatars

echo.
echo  Swagger UI : http://localhost:8000/docs
echo  Admin      : admin@origine.cm / Admin1234!
echo  Test       : jean@origine.cm  / Test1234!
echo.

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
