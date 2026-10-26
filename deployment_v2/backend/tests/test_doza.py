"""Tests API pour Doza — lancer depuis backend/ :  python -m pytest -q"""
import re
import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.main import app  # noqa: E402
from _auth import authenticate  # noqa: E402

client = TestClient(app)
authenticate(client)  # /predict est réservé au médecin : on authentifie le client

SEUIL = 0.315
BORNE_HAUTE = 0.55


def _zone_attendue(p: float) -> str:
    if p >= BORNE_HAUTE:
        return "Risque élevé"
    if p >= SEUIL:
        return "Risque intermédiaire"
    return "Risque plus faible"


def test_doza_predict_structure_et_defauts():
    """Réponse vide -> défauts ; structure, seuil et narration conformes à la spec."""
    assert "doza" in client.get("/health").json()["modules"]

    body = client.post("/api/v1/doza/predict", json={"answers": {}}).json()
    assert 0.0 <= body["proba"] <= 1.0
    assert body["seuil"] == SEUIL
    assert body["pourcentage"] == round(body["proba"] * 100)
    assert body["classe"] == int(body["proba"] >= SEUIL)
    assert body["probability"] == body["proba"]
    # zone cohérente avec le seuil / la borne haute
    assert body["zone"] == _zone_attendue(body["proba"])
    assert body["zone_taux"] in (24, 47, 68)
    # narration parlée : commence par un accueil, finit par le rappel « médecin »
    assert body["narrative"][0]["kind"] == "greeting"
    assert body["narrative"][-1]["kind"] == "closing"
    spoken = " ".join(s["text"] for s in body["narrative"])
    assert "médecin" in spoken.lower()
    # nombres écrits en toutes lettres : pas de chiffre ni de « % » parlés
    assert "%" not in spoken and not re.search(r"\d", spoken)


def test_doza_zone_classe_et_facteurs():
    """Invariants zone/classe + top-3 facteurs bien formés sur des profils variés."""
    profils = [
        {"gender": 1, "age_ordinal": 8, "admission_source_id": 7, "number_inpatient": 3,
         "A1Cresult": 3, "num_medications": 25, "diag_1_group": "Diabetes"},
        {"gender": 0, "age_ordinal": 3, "admission_type_id": 3, "number_emergency": 0,
         "A1Cresult": 1, "num_medications": 3, "diag_1_group": "Other"},
    ]
    for answers in profils:
        body = client.post("/api/v1/doza/predict", json={"answers": answers}).json()
        assert body["zone"] == _zone_attendue(body["proba"])
        assert body["classe"] == int(body["proba"] >= SEUIL)
        facteurs = body["facteurs"]
        assert len(facteurs) <= 3
        for f in facteurs:
            assert set(f) == {"champ", "reponse", "impact"}
            assert f["impact"] >= 1
        # triés par impact décroissant
        assert facteurs == sorted(facteurs, key=lambda d: d["impact"], reverse=True)
