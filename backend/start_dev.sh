#!/bin/bash
# Démarrage rapide du backend ORIGINE en local, sans MySQL.
#
# Utilise SQLite (config_sqlite.env) et le port 8001 : le port 8000 est
# occupé par un autre projet sur cette machine. Si ce n'est pas votre cas,
# vous pouvez repasser sur le port 8000 en modifiant la ligne uvicorn
# ci-dessous et lib/core/utils/constants.dart côté mobile en conséquence.
set -e
cd "$(dirname "$0")"

if [ ! -d .venv ]; then
  echo "Erreur : .venv introuvable. Créez un venv avec toutes les dépendances de requirements.txt." >&2
  exit 1
fi

if [ ! -f .env ]; then
  cp config_sqlite.env .env
  sed -i 's|APP_URL=http://localhost:8000|APP_URL=http://localhost:8001|' .env
fi

exec .venv/bin/python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
