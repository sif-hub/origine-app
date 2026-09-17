#!/bin/bash
# start.sh - Lance l'API ORIGINE en mode développement

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}"
echo "  ╔═══════════════════════════════════╗"
echo "  ║        ORIGINE API — FastAPI      ║"
echo "  ╚═══════════════════════════════════╝"
echo -e "${NC}"

# Vérifier que .env existe
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  Fichier .env introuvable — copie de .env.example${NC}"
    cp .env.example .env
    echo "📝 Éditez .env avec vos identifiants MySQL avant de continuer."
    echo "   Appuyez sur Entrée pour continuer quand même (DB en mémoire SQLite si MySQL absent)..."
    read -r
fi

# Créer l'environnement virtuel si absent
if [ ! -d "venv" ]; then
    echo "📦 Création de l'environnement virtuel..."
    python3 -m venv venv
fi

# Activer et installer
source venv/bin/activate
echo "📥 Installation des dépendances..."
pip install -r requirements.txt -q

# Créer le dossier de stockage
mkdir -p storage/uploads/avatars

echo ""
echo -e "${GREEN}🚀 Démarrage de l'API...${NC}"
echo ""
echo "  📄 Swagger UI  → http://localhost:8000/docs"
echo "  📘 ReDoc       → http://localhost:8000/redoc"
echo "  🔑 Admin       → admin@origine.cm / Admin1234!"
echo "  👤 Test        → jean@origine.cm  / Test1234!"
echo ""

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
