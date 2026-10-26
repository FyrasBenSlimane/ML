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
            raise ValueError("La tranche d'âge est invalide (ex. attendu : « [70-80] »).")
        return v

    @field_validator("hosp_days")
    @classmethod
    def _tih(cls, v):
        if not (1 <= v <= 14):
            raise ValueError("La durée d'hospitalisation doit être comprise entre 1 et 14 jours.")
        return v

    @field_validator("medications")
    @classmethod
    def _nmed(cls, v):
        if not (1 <= v <= 81):
            raise ValueError("Le nombre de médicaments doit être compris entre 1 et 81.")
        return v

    @field_validator("diagnostics")
    @classmethod
    def _ndiag(cls, v):
        if not (1 <= v <= 16):
            raise ValueError("Le nombre de diagnostics doit être compris entre 1 et 16.")
        return v

    @field_validator("diagnosis")
    @classmethod
    def _diag(cls, v):
        if v not in logic.DIAG_GROUPS:
            raise ValueError("Le motif d'hospitalisation est invalide.")
        return v

    @field_validator("glucose")
    @classmethod
    def _glu(cls, v):
        if v not in logic.GLUCOSE_VALEURS:
            raise ValueError("La glycémie max doit être : Not_Tested, Norm, >200 ou >300.")
        return v


def _narrative(res: dict) -> list:
    """Texte PARLÉ pour l'avatar (français, nombres en toutes lettres), destiné au médecin."""
    suivi, ctrl = res["suivi"], res["controle"]
    return [
        {"kind": "greeting",
         "text": "Bonjour, je suis Sora. Voici le profil de sortie du patient, destiné au médecin."},
        {"kind": "score",
         "text": f"Côté suivi : {suivi['resultat'].lower()}. La probabilité d'un besoin de suivi "
                 f"renforcé est de {pourcent(suivi['pourcentage'])}."},
        {"kind": "comparison",
         "text": f"Côté contrôle du diabète : {ctrl['resultat'].lower()}. La probabilité d'un "
                 f"diabète mal contrôlé est de {pourcent(ctrl['pourcentage'])}."},
        {"kind": "action",
         "text": f"Recommandation combinée : {res['profil'].lower()}."},
        {"kind": "closing",
         "text": "Rappel important : ce profil est une aide à la décision pour le médecin. "
                 "Il ne doit pas être montré au patient."},
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
            detail="Modèle(s) Sora indisponible(s) : vérifiez artifacts/sora/ "
                   "(sora_suivi_modele.joblib et accompagnement_modele.joblib).",
        )
    try:
        res = logic.predire(fiche.model_dump())
    except Exception as e:  # pragma: no cover - erreur de prédiction inattendue
        raise HTTPException(status_code=500, detail=f"Erreur lors de la prédiction : {e}")
    # Clé générique pour l'app (jauge pilotée par le suivi), + narration.
    return {**res, "probability": res["suivi"]["proba"], "narrative": _narrative(res)}
