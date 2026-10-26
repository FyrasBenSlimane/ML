# -*- coding: utf-8 -*-
"""Tests du portail patient — lancer depuis backend/ :  python -m pytest -q

Vérifie la règle du professeur : le modèle est réservé au médecin, et une
alerte n'arrive qu'au bon patient.
"""
import sys
import uuid
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.main import app  # noqa: E402
from app.core.security import MEDECIN_CODE_DEFAULT  # noqa: E402

client = TestClient(app)
PWD = "secret123"


def _email(prefix: str) -> str:
    return f"{prefix}-{uuid.uuid4().hex[:8]}@maak.fr"


def _register(prenom, nom, email, role="patient", code=None):
    body = {"prenom": prenom, "nom": nom, "email": email, "password": PWD, "role": role}
    if code is not None:
        body["code"] = code
    return client.post("/api/v1/auth/register", json=body)


def _bearer(token):
    return {"Authorization": f"Bearer {token}"}


# --------------------------------------------------------------------------- #
# Authentification
# --------------------------------------------------------------------------- #
def test_inscription_patient_et_me():
    email = _email("alice")
    r = _register("Alice", "Martin", email)
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["user"]["role"] == "patient"
    assert data["user"]["code"].startswith("PT-") and len(data["user"]["code"]) == 8
    me = client.get("/api/v1/auth/me", headers=_bearer(data["token"]))
    assert me.status_code == 200 and me.json()["email"] == email.lower()
    # le mot de passe ne fuit jamais
    assert "password" not in data["user"] and "password_hash" not in data["user"]


def test_connexion_mauvais_mot_de_passe():
    email = _email("bob")
    _register("Bob", "Durand", email)
    r = client.post("/api/v1/auth/login", json={"email": email, "password": "faux"})
    assert r.status_code == 401


def test_inscription_medecin_exige_le_code():
    email = _email("doc")
    assert _register("Doc", "House", email, role="medecin").status_code == 403
    assert _register("Doc", "House", email, role="medecin", code="mauvais").status_code == 403
    ok = _register("Doc", "House", email, role="medecin", code=MEDECIN_CODE_DEFAULT)
    assert ok.status_code == 200 and ok.json()["user"]["role"] == "medecin"


# --------------------------------------------------------------------------- #
# /predict réservé au médecin
# --------------------------------------------------------------------------- #
def test_predict_refuse_sans_jeton():
    r = client.post("/api/v1/doza/predict", json={"answers": {}})
    assert r.status_code == 401


def test_predict_refuse_au_patient():
    token = _register("Paul", "Petit", _email("paul")).json()["token"]
    patient = _register("Pina", "Colada", _email("pina")).json()["user"]["code"]
    r = client.post("/api/v1/doza/predict", json={"answers": {}},
                    headers={**_bearer(token), "X-Patient-Code": patient})
    assert r.status_code == 403  # un patient ne peut pas évaluer


def test_predict_medecin_sans_code_patient():
    doc = _register("Med", "Un", _email("med"), role="medecin", code=MEDECIN_CODE_DEFAULT).json()
    r = client.post("/api/v1/doza/predict", json={"answers": {}}, headers=_bearer(doc["token"]))
    assert r.status_code == 400  # code patient obligatoire


# --------------------------------------------------------------------------- #
# Alerte : au bon patient uniquement
# --------------------------------------------------------------------------- #
def test_alerte_arrive_au_bon_patient_seulement():
    doc = _register("Med", "Deux", _email("med2"), role="medecin", code=MEDECIN_CODE_DEFAULT).json()
    pa = _register("Alice", "A", _email("a")).json()["user"]
    pb = _register("Bruno", "B", _email("b")).json()["user"]
    pa_token = client.post("/api/v1/auth/login",
                           json={"email": pa["email"], "password": PWD}).json()["token"]
    pb_token = client.post("/api/v1/auth/login",
                           json={"email": pb["email"], "password": PWD}).json()["token"]
    med_h = _bearer(doc["token"])

    # Le médecin confirme le patient A
    conf = client.get(f"/api/v1/patients/{pa['code']}", headers=med_h)
    assert conf.status_code == 200 and conf.json()["prenom"] == "Alice"

    # Sans évaluation préalable, l'alerte est refusée
    early = client.post("/api/v1/notifications", headers=med_h, json={
        "patient_code": pa["code"], "module": "doza",
        "niveau": "info", "titre": "Bonjour", "message": "Test"})
    assert early.status_code == 403

    # Le médecin évalue A avec Doza
    ev = client.post("/api/v1/doza/predict", json={"answers": {}},
                     headers={**med_h, "X-Patient-Code": pa["code"]})
    assert ev.status_code == 200

    # Puis envoie une alerte bienveillante à A
    sent = client.post("/api/v1/notifications", headers=med_h, json={
        "patient_code": pa["code"], "module": "doza", "niveau": "attention",
        "titre": "Un petit ajustement", "message": "Votre médecin adapte votre suivi."})
    assert sent.status_code == 200

    # A voit son alerte...
    a_list = client.get("/api/v1/notifications", headers=_bearer(pa_token)).json()
    assert len(a_list) == 1 and a_list[0]["titre"] == "Un petit ajustement"
    assert a_list[0]["lu"] is False

    # ...mais B ne voit rien (alerte adressée au seul patient A)
    b_list = client.get("/api/v1/notifications", headers=_bearer(pb_token)).json()
    assert b_list == []

    # A marque comme lu ; B ne peut pas toucher l'alerte de A
    assert client.post(f"/api/v1/notifications/{a_list[0]['id']}/read",
                       headers=_bearer(pa_token)).status_code == 200
    assert client.post(f"/api/v1/notifications/{a_list[0]['id']}/read",
                       headers=_bearer(pb_token)).status_code == 404
    assert client.get("/api/v1/notifications", headers=_bearer(pa_token)).json()[0]["lu"] is True


def test_alerte_refusee_si_id_ne_correspond_pas_a_evaluation():
    """Le médecin a évalué A ; il ne peut pas alerter B avec l'ID de B."""
    doc = _register("Med", "Trois", _email("med3"), role="medecin",
                    code=MEDECIN_CODE_DEFAULT).json()
    pa = _register("Alice", "A", _email("a")).json()["user"]
    pb = _register("Bruno", "B", _email("b")).json()["user"]
    med_h = _bearer(doc["token"])

    # Le médecin évalue UNIQUEMENT le patient A avec Doza.
    ev = client.post("/api/v1/doza/predict", json={"answers": {}},
                     headers={**med_h, "X-Patient-Code": pa["code"]})
    assert ev.status_code == 200

    # Tenter d'alerter B (dont l'ID ne correspond à aucune évaluation) → refusé.
    bad = client.post("/api/v1/notifications", headers=med_h, json={
        "patient_code": pb["code"], "module": "doza", "niveau": "info",
        "titre": "Erreur", "message": "Mauvais patient"})
    assert bad.status_code == 403

    # B ne reçoit donc rien.
    pb_token = client.post("/api/v1/auth/login",
                           json={"email": pb["email"], "password": PWD}).json()["token"]
    assert client.get("/api/v1/notifications", headers=_bearer(pb_token)).json() == []


def test_alerte_refusee_sans_jeton_medecin():
    """Envoyer une alerte exige un jeton médecin : ni anonyme, ni patient."""
    doc = _register("Med", "Quatre", _email("med4"), role="medecin",
                    code=MEDECIN_CODE_DEFAULT).json()
    pa = _register("Alice", "A", _email("a")).json()["user"]
    med_h = _bearer(doc["token"])

    # Le médecin évalue A (pour que seul le jeton soit en cause ensuite).
    assert client.post("/api/v1/doza/predict", json={"answers": {}},
                       headers={**med_h, "X-Patient-Code": pa["code"]}).status_code == 200

    body = {"patient_code": pa["code"], "module": "doza", "niveau": "info",
            "titre": "Bonjour", "message": "Test"}

    # Sans aucun jeton → 401.
    assert client.post("/api/v1/notifications", json=body).status_code == 401

    # Avec un jeton de patient → 403 (action réservée au médecin).
    pa_token = client.post("/api/v1/auth/login",
                           json={"email": pa["email"], "password": PWD}).json()["token"]
    assert client.post("/api/v1/notifications", headers=_bearer(pa_token),
                       json=body).status_code == 403
