# -*- coding: utf-8 -*-
"""
API FastAPI pour l'application MedCare / Doza.

Lancer depuis la racine du projet :
    uvicorn main:app --app-dir api --port 8001

Endpoints :
    GET  /health          -> état du service
    POST /predict         -> Doza : prédiction du changement de dose d'insuline
    POST /accompagnement  -> Accompagnement : diabète bien / mal contrôlé
"""
from typing import Any, Dict

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, field_validator

# --- Route Doza (modèle insuline, déjà en place) ---
from predict import predire as predire_doza, SEUIL, ZONES, FEATURES

# --- Route Accompagnement (modèle de Fatma) ---
from accompagnement import predire as predire_accompagnement, modele_disponible, DIAG_GROUPS

app = FastAPI(title="MedCare — API Doza & Accompagnement", version="1.0")

# CORS limité au site PHP local (XAMPP sur :80, serveur intégré PHP sur :8000, etc.).
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["POST", "GET", "OPTIONS"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {
        "ok": True,
        "doza": {"seuil": SEUIL, "features": FEATURES},
        "accompagnement": {"disponible": modele_disponible()},
    }


# =========================================================================
# Route Doza — prédiction du changement de dose d'insuline (déjà fonctionnelle)
# =========================================================================
@app.post("/predict")
def predict(payload: Dict[str, Any]):
    # Le questionnaire envoie { answers: {...} } ; on accepte aussi un dict brut.
    answers = payload.get("answers", payload)
    return predire_doza(answers)


# =========================================================================
# Route Accompagnement — diabète bien / mal contrôlé
# =========================================================================
class FicheAccompagnement(BaseModel):
    """Les 8 champs attendus par le modèle, avec validation (messages en français)."""
    age: int
    time_in_hospital: int
    num_medications: int
    number_diagnoses: int
    diabetesMed_num: int
    insulin_prescrite: int
    metformin_prescrite: int
    diag_1_group: str

    @field_validator("age")
    @classmethod
    def _age(cls, v):
        if not (0 <= v <= 9):
            raise ValueError("L'âge doit être une tranche entre 0 et 9 (0 = [0-10), … 9 = [90-100)).")
        return v

    @field_validator("time_in_hospital")
    @classmethod
    def _tih(cls, v):
        if not (1 <= v <= 14):
            raise ValueError("La durée d'hospitalisation doit être comprise entre 1 et 14 jours.")
        return v

    @field_validator("num_medications")
    @classmethod
    def _nmed(cls, v):
        if not (1 <= v <= 81):
            raise ValueError("Le nombre de médicaments doit être compris entre 1 et 81.")
        return v

    @field_validator("number_diagnoses")
    @classmethod
    def _ndiag(cls, v):
        if not (1 <= v <= 16):
            raise ValueError("Le nombre de diagnostics doit être compris entre 1 et 16.")
        return v

    @field_validator("diabetesMed_num", "insulin_prescrite", "metformin_prescrite")
    @classmethod
    def _binaire(cls, v, info):
        if v not in (0, 1):
            raise ValueError(f"Le champ « {info.field_name} » doit valoir 0 (non) ou 1 (oui).")
        return v

    @field_validator("diag_1_group")
    @classmethod
    def _diag(cls, v):
        if v not in DIAG_GROUPS:
            raise ValueError("Le motif d'hospitalisation doit être l'une des valeurs : "
                             + ", ".join(DIAG_GROUPS) + ".")
        return v


@app.post("/accompagnement")
def accompagnement(fiche: FicheAccompagnement):
    if not modele_disponible():
        raise HTTPException(
            status_code=503,
            detail="Modèle d'accompagnement indisponible : le fichier "
                   "api/models/accompagnement_modele.joblib est absent.",
        )
    try:
        return predire_accompagnement(fiche.model_dump())
    except Exception as e:  # erreur de chargement / de prédiction
        raise HTTPException(status_code=500, detail=f"Erreur lors de la prédiction : {e}")


# =========================================================================
# TODO (Doza) : la route /predict ci-dessus est déjà opérationnelle avec le
# modèle insuline calibré (models/insulin_pipeline.joblib). Rien à inventer ici.
# =========================================================================
