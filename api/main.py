# -*- coding: utf-8 -*-
"""
API FastAPI pour l'assistant Doza.

Lancer depuis la racine du projet :
    uvicorn main:app --app-dir api --port 8001

Endpoints :
    GET  /health   -> etat du service
    POST /predict  -> { answers: {...} }  ou directement {...}  -> resultat de `predire`
"""
from typing import Any, Dict

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from predict import predire, SEUIL, ZONES, FEATURES

app = FastAPI(title="Doza — prédiction du changement d'insuline", version="1.0")

# Le front-end PHP tourne sur un autre port (8000) : on autorise les appels cross-origin.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST", "GET", "OPTIONS"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"ok": True, "features": FEATURES, "seuil": SEUIL, "zones": ZONES}


@app.post("/predict")
def predict(payload: Dict[str, Any]):
    # Le questionnaire envoie { answers: {...} } ; on accepte aussi un dict de reponses brut.
    answers = payload.get("answers", payload)
    return predire(answers)
