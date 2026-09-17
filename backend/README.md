# ORIGINE API — FastAPI

## Comptes par défaut (prêts à l'emploi)

| Rôle          | Email                | Mot de passe |
|---------------|----------------------|--------------|
| **ADMIN**     | admin@origine.cm     | Admin1234!   |
| **UTILISATEUR** | jean@origine.cm    | Test1234!    |

Les comptes sont créés automatiquement au premier démarrage. Aucune manipulation SQL nécessaire.

---

## Installation

```bash
cd origine_api

# 1. Environnement virtuel
python -m venv venv
source venv/bin/activate      # Linux/Mac
venv\Scripts\activate         # Windows

# 2. Dépendances
pip install -r requirements.txt

# 3. Configuration
cp .env.example .env
# Éditer .env : renseigner DB_HOST, DB_USER, DB_PASS, JWT_SECRET
# Pour l'IA : renseigner CLAUDE_API_KEY ou OPENAI_API_KEY

# 4. Démarrer
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

L'API démarre et crée automatiquement :
- Toutes les tables MySQL
- Les 2 comptes par défaut
- Les fournisseurs IA

---

## Documentation interactive

Une fois l'API démarrée :
- **Swagger UI** → http://localhost:8000/docs
- **ReDoc**      → http://localhost:8000/redoc

---

## Tester la connexion avec curl

```bash
# Connexion admin
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@origine.cm","mot_de_passe":"Admin1234!"}'

# Récupérer le profil (remplacer TOKEN par l'access_token reçu)
curl http://localhost:8000/api/auth/me \
  -H "Authorization: Bearer TOKEN"
```

---

## Fichier .env minimal

```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=origine_db
DB_USER=root
DB_PASS=

JWT_SECRET=change_this_to_a_random_64_char_string

# Renseigner au moins une clé IA
CLAUDE_API_KEY=sk-ant-...
```

---

## Endpoints disponibles

### Authentification
| Méthode | URL | Description |
|---------|-----|-------------|
| POST | `/api/auth/register` | Inscription |
| POST | `/api/auth/login` | Connexion |
| POST | `/api/auth/refresh` | Rafraîchir le token |
| POST | `/api/auth/logout` | Déconnexion |
| GET  | `/api/auth/me` | Profil connecté |

### Profil
| Méthode | URL | Description |
|---------|-----|-------------|
| GET  | `/api/profile` | Voir le profil |
| PUT  | `/api/profile` | Modifier le profil |
| POST | `/api/profile/avatar` | Changer la photo |
| POST | `/api/profile/password` | Changer le mot de passe |

### Généalogie
| Méthode | URL | Description |
|---------|-----|-------------|
| POST | `/api/families` | Créer une famille |
| GET  | `/api/families` | Lister mes familles |
| GET  | `/api/families/{id}/tree` | Arbre JSON |
| GET  | `/api/families/{id}/timeline` | Chronologie |
| POST | `/api/families/merge` | Fusionner deux arbres |
| POST | `/api/persons` | Ajouter une personne |
| GET/PUT/DELETE | `/api/persons/{id}` | Gérer une personne |
| POST | `/api/persons/{id}/parent` | Ajouter un parent |
| POST | `/api/persons/{id}/child` | Ajouter un enfant |
| POST | `/api/persons/{id}/spouse` | Ajouter un conjoint |
| POST | `/api/persons/{id}/link` | Lier deux personnes |

### ORIGINE AI
| Méthode | URL | Description |
|---------|-----|-------------|
| POST | `/api/ai/chat` | Chatbot conversationnel |
| POST | `/api/ai/search` | Recherche en langage naturel |
| POST | `/api/ai/culture/tradition` | Expliquer une tradition |
| POST | `/api/ai/culture/name-meaning` | Signification d'un nom |
| POST | `/api/ai/culture/clan` | Expliquer un clan |
| POST | `/api/ai/history/summarize` | Résumer une histoire |
| POST | `/api/ai/history/narrative` | Rédiger un récit |

---

## Structure du projet

```
origine_api/
├── app/
│   ├── main.py              → Point d'entrée FastAPI + init DB + comptes par défaut
│   ├── core/
│   │   ├── config.py        → Settings (pydantic-settings, lecture .env)
│   │   ├── database.py      → SQLAlchemy engine + session + get_db
│   │   └── security.py      → JWT, bcrypt, dépendances get_current_user
│   ├── models/
│   │   ├── user.py          → User, RefreshToken, LoginAttempt
│   │   ├── genealogy.py     → Family, Person, Relationship, Tribe, Clan
│   │   └── ai.py            → AIProvider, AILog
│   ├── schemas/
│   │   ├── auth.py          → Pydantic: Register, Login, UpdateProfile...
│   │   ├── genealogy.py     → Pydantic: FamilyCreate, PersonCreate, Link...
│   │   └── ai.py            → Pydantic: Chat, Search, Tradition...
│   ├── services/
│   │   ├── auth_service.py  → register, login, refresh, logout
│   │   ├── genealogy_service.py → arbre, relations, fusion
│   │   └── ai_service.py    → AIManager multi-fournisseurs + assistants
│   └── routers/
│       ├── auth.py
│       ├── profile.py
│       ├── genealogy.py
│       └── ai.py
├── storage/uploads/         → Avatars et fichiers
├── requirements.txt
├── .env.example
└── README.md
```
