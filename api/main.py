# -*- coding: utf-8 -*-
"""
API FastAPI pour l'application MAAK / Doza.

Lancer depuis la racine du projet :
    uvicorn main:app --app-dir api --port 8001

Endpoints :
    GET  /health          -> état du service
    POST /predict         -> Doza : prédiction du changement de dose d'insuline
    POST /accompagnement  -> Accompagnement : diabète bien / mal contrôlé
"""
import re
from typing import Any, Dict

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, field_validator

# --- Route Doza (modèle insuline, déjà en place) ---
from predict import predire as predire_doza, SEUIL, ZONES, FEATURES

# --- Modèle M2 "Contrôle" (bien / mal contrôlé) — route /accompagnement + bloc /sora ---
from accompagnement import (predire as predire_controle,
                            modele_disponible as controle_disponible, DIAG_GROUPS)

# --- Modèle M1 "Suivi" (suivi renforcé / léger) — bloc /sora ---
from sora_suivi import predire as predire_suivi, modele_disponible as suivi_disponible

app = FastAPI(title="MAAK — API Doza & Accompagnement", version="1.0")

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
        "accompagnement": {"disponible": controle_disponible()},
        "sora": {"suivi": suivi_disponible(), "controle": controle_disponible()},
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
    """Teste le modèle M2 (Contrôle) seul."""
    if not controle_disponible():
        raise HTTPException(
            status_code=503,
            detail="Modèle d'accompagnement indisponible : le fichier "
                   "api/models/accompagnement_modele.joblib est absent.",
        )
    try:
        return predire_controle(fiche.model_dump())
    except Exception as e:  # erreur de chargement / de prédiction
        raise HTTPException(status_code=500, detail=f"Erreur lors de la prédiction : {e}")


# =========================================================================
# Route Sora — profil de sortie (M1 Suivi + M2 Contrôle)
# =========================================================================
GLUCOSE_VALEURS = {"Not_Tested", "Norm", ">200", ">300"}

# Profil combiné : (classe_suivi, classe_controle) -> message
PROFILS = {
    (0, 0): "Suivi allégé, conseils standards",
    (0, 1): "Peu de rendez-vous, programme pédagogique recommandé",
    (1, 0): "Rendez-vous réguliers, pas de programme spécifique",
    (1, 1): "Suivi rapproché et programme pédagogique",
}


class FicheSora(BaseModel):
    """Champs envoyés par le formulaire Sora (app/Views/sora/index.php)."""
    age: str                 # ex. "[70-80]"
    hosp_days: int
    medications: int
    diagnostics: int
    diagnosis: str           # diag_1_group
    glucose: str             # max_glu_serum
    antidiabetic: str        # "Oui" / "Non"
    insulin: str             # "Oui" / "Non" / "Up" / "Down"
    metformin: str           # "Oui" / "Non" / "Steady"

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
        if v not in DIAG_GROUPS:
            raise ValueError("Le motif d'hospitalisation est invalide.")
        return v

    @field_validator("glucose")
    @classmethod
    def _glu(cls, v):
        if v not in GLUCOSE_VALEURS:
            raise ValueError("La glycémie max doit être : Not_Tested, Norm, >200 ou >300.")
        return v


def _vers_features(f: FicheSora) -> dict:
    """Convertit la fiche du formulaire vers les features attendues par les modèles."""
    age = int(re.search(r"\d+", f.age).group()) // 10            # "[70-80]" -> 7
    return {
        "age": age,
        "time_in_hospital": f.hosp_days,
        "num_medications": f.medications,
        "number_diagnoses": f.diagnostics,
        "diabetesMed_num": 1 if f.antidiabetic == "Oui" else 0,
        "insulin_prescrite": 0 if f.insulin in ("Non", "No") else 1,     # Up/Down/Oui/Steady -> 1
        "metformin_prescrite": 0 if f.metformin in ("Non", "No") else 1,
        "diag_1_group": f.diagnosis,
        "max_glu_serum": f.glucose,                                       # utilisé par M1 seulement
    }


@app.post("/sora")
def sora(fiche: FicheSora):
    if not (suivi_disponible() and controle_disponible()):
        raise HTTPException(
            status_code=503,
            detail="Modèle(s) Sora indisponible(s) : vérifiez api/models/ "
                   "(sora_suivi_modele.joblib et accompagnement_modele.joblib).",
        )
    try:
        feats = _vers_features(fiche)
        suivi = predire_suivi(feats)       # M1 (9 features, dont max_glu_serum)
        ctrl = predire_controle(feats)     # M2 (8 features, ignore max_glu_serum)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la prédiction : {e}")

    return {
        "suivi": {k: suivi[k] for k in ("proba", "pourcentage", "classe", "seuil", "resultat")},
        "controle": {k: ctrl[k] for k in ("proba", "pourcentage", "classe", "seuil", "resultat")},
        "profil": PROFILS[(suivi["classe"], ctrl["classe"])],
    }


# =========================================================================
# TODO (Doza) : la route /predict ci-dessus est déjà opérationnelle avec le
# modèle insuline calibré (models/insulin_pipeline.joblib). Rien à inventer ici.
# =========================================================================
