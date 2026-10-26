# -*- coding: utf-8 -*-
"""Aide aux tests : crée un médecin + un patient et authentifie le client.

Chaque appel utilise des e-mails uniques (la base de test est partagée par la
session), puis pose les en-têtes « Authorization » et « X-Patient-Code » sur le
client pour que les tests existants des modèles passent la garde des /predict.
"""
import os
import uuid

# Doit rester aligné avec security.MEDECIN_CODE_DEFAULT (évite d'importer l'app
# avant que le chemin ne soit prêt).
_MEDECIN_CODE = os.getenv("MAAK_MEDECIN_CODE", "MAAK-MED-2024")
_PWD = "secret123"


def authenticate(client) -> str:
    """Enregistre un médecin + un patient, connecte le médecin, renvoie l'ID patient."""
    tag = uuid.uuid4().hex[:8]
    client.post("/api/v1/auth/register", json={
        "prenom": "Doc", "nom": tag, "email": f"doc-{tag}@maak.fr",
        "password": _PWD, "role": "medecin", "code": _MEDECIN_CODE})
    token = client.post("/api/v1/auth/login", json={
        "email": f"doc-{tag}@maak.fr", "password": _PWD}).json()["token"]
    patient = client.post("/api/v1/auth/register", json={
        "prenom": "Pat", "nom": tag, "email": f"pat-{tag}@maak.fr",
        "password": _PWD, "role": "patient"}).json()
    code = patient["user"]["code"]
    client.headers.update({"Authorization": f"Bearer {token}", "X-Patient-Code": code})
    return code
