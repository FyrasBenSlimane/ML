# -*- coding: utf-8 -*-
"""
Modèle "Sora — Suivi" (M1) : prédit si le patient a besoin d'un suivi renforcé
à la sortie (cible = 1 si au moins une visite de suivi).

Même format que les autres modèles : dictionnaire joblib
    "modele" / "seuil" / "features" / "messages"
Chargé UNE SEULE FOIS, puis réutilisé.

9 features : age, time_in_hospital, num_medications, number_diagnoses,
             diabetesMed_num, insulin_prescrite, metformin_prescrite,
             diag_1_group, max_glu_serum.
"""
from pathlib import Path

import joblib
import pandas as pd

ROOT = Path(__file__).resolve().parent
MODEL_PATH = ROOT / "models" / "sora_suivi_modele.joblib"

_bundle = None


def modele_disponible() -> bool:
    return MODEL_PATH.exists()


def _charger():
    global _bundle
    if _bundle is None:
        if not MODEL_PATH.exists():
            raise FileNotFoundError(
                f"Modèle introuvable : {MODEL_PATH}. "
                "Placez 'sora_suivi_modele.joblib' dans api/models/."
            )
        b = joblib.load(MODEL_PATH)
        _bundle = {
            "modele": b["modele"],
            "seuil": float(b["seuil"]),
            "features": list(b["features"]),
        }
    return _bundle


def predire(data: dict) -> dict:
    """data : dict contenant au moins les features du modèle (déjà converties)."""
    b = _charger()
    row = {f: data[f] for f in b["features"]}
    X = pd.DataFrame([row], columns=b["features"])

    proba = float(b["modele"].predict_proba(X)[0, 1])
    classe = int(proba >= b["seuil"])

    return {
        "proba": round(proba, 4),
        "pourcentage": round(proba * 100),
        "classe": classe,
        "seuil": round(b["seuil"], 4),
        # classe 1 = besoin d'un suivi renforcé
        "resultat": "Suivi renforcé" if classe == 1 else "Suivi léger",
    }
