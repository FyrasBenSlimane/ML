"""Tests API pour Sora — lancer depuis backend/ :  python -m pytest -q"""
import re
import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.main import app  # noqa: E402
from _auth import authenticate  # noqa: E402

client = TestClient(app)
authenticate(client)  # /predict est réservé au médecin : on authentifie le client

PROFILS = {
    (0, 0): "Light follow-up, standard advice",
    (0, 1): "Few appointments, educational program recommended",
    (1, 0): "Regular appointments, no specific program",
    (1, 1): "Close follow-up and educational program",
}

FICHE = {
    "age": "[70-80]", "hosp_days": 6, "medications": 18, "diagnostics": 9,
    "diagnosis": "Circulatory", "glucose": ">200",
    "antidiabetic": "Oui", "insulin": "Up", "metformin": "Steady",
}


def test_sora_predict_combine_et_narration():
    """M1 + M2 -> profil ; structure, seuils et narration conformes à la spec."""
    assert "sora" in client.get("/health").json()["modules"]

    body = client.post("/api/v1/sora/predict", json=FICHE).json()
    suivi, ctrl = body["suivi"], body["controle"]

    for bloc, resultats in ((suivi, ("Enhanced follow-up", "Light follow-up")),
                            (ctrl, ("Poorly controlled", "Well controlled"))):
        assert 0.0 <= bloc["proba"] <= 1.0
        assert bloc["classe"] in (0, 1)
        assert bloc["resultat"] in resultats
        assert bloc["classe"] == int(bloc["proba"] >= bloc["seuil"])

    # profil = combinaison exacte des deux classes
    assert body["profil"] == PROFILS[(suivi["classe"], ctrl["classe"])]
    # jauge de l'app pilotée par le suivi
    assert body["probability"] == suivi["proba"]

    # narration parlée, destinée au médecin, nombres en toutes lettres
    assert body["narrative"][0]["kind"] == "greeting"
    assert body["narrative"][-1]["kind"] == "closing"
    spoken = " ".join(s["text"] for s in body["narrative"])
    assert "doctor" in spoken.lower()
    assert "%" not in spoken and not re.search(r"\d", spoken)


def test_sora_validation_des_entrees():
    """Les bornes et valeurs invalides sont rejetées (422)."""
    assert client.post("/api/v1/sora/predict", json={**FICHE, "diagnosis": "Astrology"}).status_code == 422
    assert client.post("/api/v1/sora/predict", json={**FICHE, "hosp_days": 40}).status_code == 422
    assert client.post("/api/v1/sora/predict", json={**FICHE, "glucose": "???"}).status_code == 422
    # une fiche valide passe
    assert client.post("/api/v1/sora/predict", json=FICHE).status_code == 200
