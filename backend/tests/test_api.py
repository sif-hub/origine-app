# tests/test_api.py
"""
Tests d'intégration ORIGINE API.
Utilise SQLite en mémoire — aucune DB externe requise.

Lancer :
    pip install pytest httpx
    pytest tests/ -v
"""

import os
import pytest
from fastapi.testclient import TestClient

# Forcer SQLite en mémoire avant tout import de l'app
os.environ.update({
    "DB_HOST": "",
    "DB_NAME": ":memory:",
    "DB_USER": "",
    "DB_PASS": "",
    "JWT_SECRET": "test_secret_key_32_chars_minimum!!",
    "APP_DEBUG": "false",
    "UPLOAD_DIR": "/tmp/origine_test_uploads",
})

from app.main import app  # noqa: E402

client = TestClient(app)

# ─── DONNÉES DE TEST ──────────────────────────────────────────────────
TEST_ADMIN = {"email": "admin@origine.cm", "mot_de_passe": "Admin1234!"}
TEST_USER  = {"email": "jean@origine.cm",  "mot_de_passe": "Test1234!"}


def _get_token(credentials: dict) -> str:
    r = client.post("/api/auth/login", json=credentials)
    assert r.status_code == 200, f"Login failed: {r.text}"
    return r.json()["data"]["access_token"]


# ─── SANTÉ ────────────────────────────────────────────────────────────
def test_health():
    r = client.get("/")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_docs_available():
    r = client.get("/docs")
    assert r.status_code == 200


# ─── AUTHENTIFICATION ─────────────────────────────────────────────────
def test_login_admin_success():
    r = client.post("/api/auth/login", json=TEST_ADMIN)
    assert r.status_code == 200
    data = r.json()["data"]
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["role"] == "ADMIN"


def test_login_user_success():
    r = client.post("/api/auth/login", json=TEST_USER)
    assert r.status_code == 200
    assert r.json()["data"]["user"]["email"] == TEST_USER["email"]


def test_login_wrong_password():
    r = client.post("/api/auth/login", json={"email": "admin@origine.cm", "mot_de_passe": "MAUVAIS"})
    assert r.status_code == 401


def test_login_unknown_email():
    r = client.post("/api/auth/login", json={"email": "inconnu@test.cm", "mot_de_passe": "Test1234!"})
    assert r.status_code == 401


def test_register_new_user():
    r = client.post("/api/auth/register", data={
        "nom": "Ngo",
        "prenom": "Sophie",
        "email": "sophie.ngo@test.cm",
        "sexe": "F",
        "mot_de_passe": "Sophie1234!",
    })
    assert r.status_code == 201
    assert r.json()["data"]["user"]["email"] == "sophie.ngo@test.cm"


def test_register_duplicate_email():
    r = client.post("/api/auth/register", data={
        "nom": "Admin",
        "prenom": "Bis",
        "email": "admin@origine.cm",
        "sexe": "M",
        "mot_de_passe": "Admin1234!",
    })
    assert r.status_code == 409


def test_me_authenticated():
    token = _get_token(TEST_ADMIN)
    r = client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert r.json()["data"]["user"]["role"] == "ADMIN"


def test_me_unauthenticated():
    r = client.get("/api/auth/me")
    assert r.status_code == 403  # HTTPBearer retourne 403 sans header


def test_me_invalid_token():
    r = client.get("/api/auth/me", headers={"Authorization": "Bearer token_invalide"})
    assert r.status_code == 401


def test_refresh_token():
    r = client.post("/api/auth/login", json=TEST_USER)
    refresh = r.json()["data"]["refresh_token"]
    r2 = client.post("/api/auth/refresh", json={"refresh_token": refresh})
    assert r2.status_code == 200
    assert "access_token" in r2.json()["data"]


def test_logout():
    r = client.post("/api/auth/login", json=TEST_USER)
    refresh = r.json()["data"]["refresh_token"]
    r2 = client.post("/api/auth/logout", json={"refresh_token": refresh})
    assert r2.status_code == 200


# ─── PROFIL ───────────────────────────────────────────────────────────
def test_get_profile():
    token = _get_token(TEST_USER)
    r = client.get("/api/profile", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert "profile" in r.json()["data"]


def test_update_profile():
    token = _get_token(TEST_USER)
    r = client.put("/api/profile",
        headers={"Authorization": f"Bearer {token}"},
        json={"biographie": "Nouvelle biographie de test.", "region": "Littoral"},
    )
    assert r.status_code == 200
    assert r.json()["data"]["profile"]["region"] == "Littoral"


def test_change_password_wrong_current():
    token = _get_token(TEST_USER)
    r = client.post("/api/profile/password",
        headers={"Authorization": f"Bearer {token}"},
        json={"mot_de_passe_actuel": "MAUVAIS", "nouveau_mot_de_passe": "Nouveau1234!"},
    )
    assert r.status_code == 400


# ─── GÉNÉALOGIE ───────────────────────────────────────────────────────
def test_create_family():
    token = _get_token(TEST_USER)
    r = client.post("/api/families",
        headers={"Authorization": f"Bearer {token}"},
        json={"nom": "Famille Mbarga", "visibilite": "PRIVE"},
    )
    assert r.status_code == 201
    assert r.json()["data"]["family"]["nom"] == "Famille Mbarga"


def test_list_families():
    token = _get_token(TEST_USER)
    r = client.get("/api/families", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert isinstance(r.json()["data"]["families"], list)


def test_add_person():
    token = _get_token(TEST_USER)
    # Créer une famille d'abord
    family_r = client.post("/api/families",
        headers={"Authorization": f"Bearer {token}"},
        json={"nom": "Famille Test Personne"},
    )
    family_id = family_r.json()["data"]["family"]["id"]

    r = client.post("/api/persons",
        headers={"Authorization": f"Bearer {token}"},
        json={"nom": "Ngo", "prenom": "Marie", "sexe": "F", "family_id": family_id},
    )
    assert r.status_code == 201
    person = r.json()["data"]["person"]
    assert person["nom"] == "Ngo"
    return person["id"], family_id, token


def test_get_tree():
    token = _get_token(TEST_USER)
    family_r = client.post("/api/families",
        headers={"Authorization": f"Bearer {token}"},
        json={"nom": "Famille Arbre Test"},
    )
    family_id = family_r.json()["data"]["family"]["id"]

    r = client.get(f"/api/families/{family_id}/tree",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200
    tree = r.json()["data"]["tree"]
    assert "nodes" in tree
    assert "edges" in tree


def test_get_timeline():
    token = _get_token(TEST_USER)
    family_r = client.post("/api/families",
        headers={"Authorization": f"Bearer {token}"},
        json={"nom": "Famille Timeline"},
    )
    family_id = family_r.json()["data"]["family"]["id"]
    r = client.get(f"/api/families/{family_id}/timeline",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200


def test_add_parent_child_spouse():
    token = _get_token(TEST_USER)
    family_r = client.post("/api/families",
        headers={"Authorization": f"Bearer {token}"},
        json={"nom": "Famille Relations"},
    )
    fid = family_r.json()["data"]["family"]["id"]

    # Personne racine
    p = client.post("/api/persons",
        headers={"Authorization": f"Bearer {token}"},
        json={"nom": "Atangana", "prenom": "Paul", "sexe": "M", "family_id": fid},
    ).json()["data"]["person"]

    # Père
    r_père = client.post(f"/api/persons/{p['id']}/parent",
        headers={"Authorization": f"Bearer {token}"},
        json={"nom": "Atangana", "prenom": "Jean", "sexe": "M", "family_id": fid},
    )
    assert r_père.status_code == 201

    # Enfant
    r_enfant = client.post(f"/api/persons/{p['id']}/child",
        headers={"Authorization": f"Bearer {token}"},
        json={"nom": "Atangana", "prenom": "Sophie", "sexe": "F", "family_id": fid},
    )
    assert r_enfant.status_code == 201

    # Conjoint
    r_conjoint = client.post(f"/api/persons/{p['id']}/spouse",
        headers={"Authorization": f"Bearer {token}"},
        json={"nom": "Ngo", "prenom": "Claire", "sexe": "F", "family_id": fid},
    )
    assert r_conjoint.status_code == 201


def test_update_person():
    token = _get_token(TEST_USER)
    r = client.post("/api/persons",
        headers={"Authorization": f"Bearer {token}"},
        json={"nom": "Essomba", "prenom": "Claude"},
    )
    pid = r.json()["data"]["person"]["id"]

    r2 = client.put(f"/api/persons/{pid}",
        headers={"Authorization": f"Bearer {token}"},
        json={"notes": "Ancêtre fondateur du clan"},
    )
    assert r2.status_code == 200
    assert r2.json()["data"]["person"]["notes"] == "Ancêtre fondateur du clan"


def test_delete_person():
    token = _get_token(TEST_USER)
    r = client.post("/api/persons",
        headers={"Authorization": f"Bearer {token}"},
        json={"nom": "ASupprimer", "prenom": "Test"},
    )
    pid = r.json()["data"]["person"]["id"]

    r2 = client.delete(f"/api/persons/{pid}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r2.status_code == 204
