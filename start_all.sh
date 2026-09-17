#!/bin/bash
# start_all.sh — Lance toute l'application ORIGINE

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${GREEN}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║           ORIGINE — Démarrage            ║"
echo "  ║  Plateforme généalogique camerounaise    ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ── BACKEND ──────────────────────────────────────────────────────────
echo -e "${CYAN}[1/2] Démarrage du Backend FastAPI...${NC}"
cd backend

if [ ! -f ".env" ]; then
    echo -e "${YELLOW}  ⚠️  .env absent → copie de .env.example${NC}"
    cp .env.example .env
fi

if [ ! -d "venv" ]; then
    echo "  📦 Création de l'environnement virtuel..."
    python3 -m venv venv
fi

source venv/bin/activate
pip install -r requirements.txt -q
mkdir -p storage/uploads/avatars

echo -e "${GREEN}  ✅ Backend prêt${NC}"
echo "     → http://localhost:8000"
echo "     → http://localhost:8000/docs (Swagger)"
echo ""

# Lancement en arrière-plan
uvicorn app.main:app --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!
echo "  PID backend : $BACKEND_PID"
sleep 2

# ── MOBILE ───────────────────────────────────────────────────────────
cd ../mobile

echo -e "${CYAN}[2/2] Préparation du Mobile Flutter...${NC}"
flutter pub get -q

echo ""
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ ORIGINE est prêt !${NC}"
echo ""
echo "  🌐 API       : http://localhost:8000"
echo "  📄 Swagger   : http://localhost:8000/docs"
echo ""
echo "  🔑 Connexion :"
echo "     admin@origine.cm  →  Admin1234!"
echo "     jean@origine.cm   →  Test1234!"
echo ""
echo -e "${YELLOW}  👉 Pour lancer le mobile :${NC}"
echo "     cd mobile && flutter run"
echo ""
echo "  Pour arrêter le backend : kill $BACKEND_PID"
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
