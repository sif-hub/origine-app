# ORIGINE — Application Complète

Plateforme numérique camerounaise de généalogie et de patrimoine culturel.

```
ORIGINE_APP/
├── backend/     → API REST FastAPI (Python)
└── mobile/      → Application Flutter (iOS / Android)
```

---

## 🚀 Démarrage rapide

### Étape 1 — Lancer le backend

```bash
cd backend

# Linux / Mac
chmod +x start.sh && ./start.sh

# Windows
start.bat
```

L'API démarre sur **http://localhost:8000**

### Étape 2 — Configurer le mobile

Ouvrir `mobile/lib/core/utils/constants.dart` et ajuster `apiBaseUrl` :

| Situation | URL |
|---|---|
| Émulateur Android | `http://10.0.2.2:8000/api` |
| Simulateur iOS | `http://127.0.0.1:8000/api` |
| Téléphone réel (Wi-Fi) | `http://TON_IP_LAN:8000/api` |

Ou en une commande :
```bash
# Émulateur Android
sed -i "s|apiBaseUrl = '.*'|apiBaseUrl = 'http://10.0.2.2:8000/api'|" \
  mobile/lib/core/utils/constants.dart

# Appareil physique (remplacer l'IP)
sed -i "s|apiBaseUrl = '.*'|apiBaseUrl = 'http://172.20.10.2:8000/api'|" \
  mobile/lib/core/utils/constants.dart
```

### Étape 3 — Lancer le mobile

```bash
cd mobile
flutter pub get
flutter run
```

---

## 🔑 Comptes par défaut

| Rôle | Email | Mot de passe |
|---|---|---|
| **ADMIN** | admin@origine.cm | Admin1234! |
| **Utilisateur** | jean@origine.cm | Test1234! |

Créés automatiquement au premier démarrage du backend.

---

## 📄 Documentation API

Une fois le backend lancé :
- **Swagger UI** → http://localhost:8000/docs
- **ReDoc**      → http://localhost:8000/redoc

---

## 🗂️ Stack technique

| Couche | Technologie |
|---|---|
| Backend | Python 3.11+ / FastAPI / SQLAlchemy |
| Base de données | MySQL 8+ (ou SQLite pour les tests) |
| Mobile | Flutter 3.x / Dart |
| State management | BLoC + GoRouter |
| IA | OpenAI / Claude / Gemini / DeepSeek |
| Auth | JWT (access + refresh token) |

---

## 🧪 Tests backend (sans MySQL)

```bash
cd backend
cp config_sqlite.env .env   # SQLite, aucun serveur requis
source venv/bin/activate
pip install pytest httpx
pytest tests/ -v
```

---

## 🌿 Couleurs ORIGINE

| Token | Hex | Usage |
|---|---|---|
| Vert Forêt | `#0A3D2E` | AppBar, boutons principaux |
| Vert Clair | `#1D7A4C` | Accents, bulles chat |
| Or / Savane | `#C9942C` | Boutons CTA |
| Crème | `#F7F3EC` | Fond de l'application |
# origine-app
