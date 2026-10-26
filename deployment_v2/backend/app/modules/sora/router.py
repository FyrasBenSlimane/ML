# -*- coding: utf-8 -*-
"""Endpoints Sora — montés sur /api/v1/sora par le registre de modules."""
import re

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, field_validator

from . import logic
from .french import pourcent

router = APIRouter()


class FicheSora(BaseModel):
    """Champs cliniques saisis par le médecin (libellés FR, valeurs modèle inchangées)."""
    age: str = "[60-70]"        # ex. "[70-80]"
    hosp_days: int = 4
    medications: int = 13
    diagnostics: int = 7
    diagnosis: str = "Circulatory"   # diag_1_group
    glucose: str = "Not_Tested"      # max_glu_serum
    antidiabetic: str = "Oui"
    insulin: str = "Non"             # "Oui" / "Non" / "Up" / "Down"
    metformin: str = "Non"           # "Oui" / "Non" / "Steady"

    @field_validator("age")
    @classmethod
    def _age(cls, v):
        m = re.search(r"\d+", v or "")
        if not m or not (0 <= int(m.group()) // 10 <= 9):
            raise ValueError("Invalid age range (expected e.g. “[70-80]”).")
        return v

    @field_validator("hosp_days")
    @classmethod
    def _tih(cls, v):
        if not (1 <= v <= 14):
            raise ValueError("Length of stay must be between 1 and 14 days.")
        return v

    @field_validator("medications")
    @classmethod
    def _nmed(cls, v):
        if not (1 <= v <= 81):
            raise ValueError("Number of medications must be between 1 and 81.")
        return v

    @field_validator("diagnostics")
    @classmethod
    def _ndiag(cls, v):
        if not (1 <= v <= 16):
            raise ValueError("Number of diagnoses must be between 1 and 16.")
        return v

    @field_validator("diagnosis")
    @classmethod
    def _diag(cls, v):
        if v not in logic.DIAG_GROUPS:
            raise ValueError("Invalid reason for admission.")
        return v

    @field_validator("glucose")
    @classmethod
    def _glu(cls, v):
        if v not in logic.GLUCOSE_VALEURS:
            raise ValueError("Max glucose must be: Not_Tested, Norm, >200 or >300.")
        return v


def _narrative(res: dict) -> list:
    """SPOKEN text for the avatar (English, numbers spelled out), for the doctor."""
    suivi, ctrl = res["suivi"], res["controle"]
    return [
        {"kind": "greeting",
         "text": "Hello, I'm Sora. Here is the patient's discharge profile, for the doctor."},
        {"kind": "score",
         "text": f"On follow-up: {suivi['resultat'].lower()}. The probability of needing enhanced "
                 f"follow-up is {pourcent(suivi['pourcentage'])}."},
        {"kind": "comparison",
         "text": f"On diabetes control: {ctrl['resultat'].lower()}. The probability of poorly "
                 f"controlled diabetes is {pourcent(ctrl['pourcentage'])}."},
        {"kind": "action",
         "text": f"Combined recommendation: {res['profil'].lower()}."},
        {"kind": "closing",
         "text": "Important reminder: this profile is a decision aid for the doctor. "
                 "It must not be shown to the patient."},
    ]


@router.get("/meta", summary="Disponibilité des modèles et groupes de diagnostic")
def meta():
    return {
        "model": {"name": "Sora · Suivi (M1) + Contrôle (M2)",
                  "owner": "Fatma",
                  "target": "Profil de sortie : intensité du suivi × contrôle du diabète"},
        "disponible": logic.modeles_disponibles(),
        "diag_groups": logic.DIAG_GROUPS,
        "glucose": sorted(logic.GLUCOSE_VALEURS),
    }


@router.post("/predict", summary="Profil de sortie (M1 Suivi + M2 Contrôle)")
def predict(fiche: FicheSora):
    if not logic.modeles_disponibles():
        raise HTTPException(
            status_code=503,
            detail="Sora model(s) unavailable: check artifacts/sora/ "
                   "(sora_suivi_modele.joblib and accompagnement_modele.joblib).",
        )
    try:
        res = logic.predire(fiche.model_dump())
    except Exception as e:  # pragma: no cover - erreur de prédiction inattendue
        raise HTTPException(status_code=500, detail=f"Prediction error: {e}")
    # Clé générique pour l'app (jauge pilotée par le suivi), + narration.
    return {**res, "probability": res["suivi"]["proba"], "narrative": _narrative(res)}
