# -*- coding: utf-8 -*-
"""
Sora — profil de sortie (deux modèles combinés), logique métier.

Reproduit EXACTEMENT la spec (`Projet ML/api/sora_suivi.py`, `accompagnement.py`,
`main.py`) :
  * M1 « Suivi »     : 9 features, classe 1 = « Suivi renforcé ».
  * M2 « Contrôle »  : 8 features (= M1 sans max_glu_serum), classe 1 = « Mal contrôlé ».
  * profil           : combinaison (classe_suivi, classe_controle).

Les deux bundles joblib (modele / seuil / features / messages) sont chargés UNE
SEULE FOIS depuis artifacts/sora/. On ne modifie jamais les VALEURS envoyées aux
modèles (anglais) ; seuls les libellés affichés sont en français.
"""
import re
from functools import lru_cache

import joblib
import pandas as pd

from app.core.config import ARTIFACTS_DIR

ARTIFACT_DIR = ARTIFACTS_DIR / "sora"
SUIVI_PATH = ARTIFACT_DIR / "sora_suivi_modele.joblib"
CONTROLE_PATH = ARTIFACT_DIR / "accompagnement_modele.joblib"

# Groupes ICD-9 autorisés pour le motif principal d'hospitalisation.
DIAG_GROUPS = ["Circulatory", "Diabetes", "Respiratory", "Digestive", "Injury",
               "Musculoskeletal", "Genitourinary", "Neoplasms", "External", "Other"]
GLUCOSE_VALEURS = {"Not_Tested", "Norm", ">200", ">300"}

# Profil combiné : (classe_suivi, classe_controle) -> recommandation.
PROFILS = {
    (0, 0): "Light follow-up, standard advice",
    (0, 1): "Few appointments, educational program recommended",
    (1, 0): "Regular appointments, no specific program",
    (1, 1): "Close follow-up and educational program",
}

# Messages affichés (libellés en anglais pour toute l'application).
MESSAGES_CONTROLE_FR = {
    1: "Educational program recommended (diet, physical activity)",
    0: "Standard advice, no specific program",
}


def modeles_disponibles() -> bool:
    return SUIVI_PATH.exists() and CONTROLE_PATH.exists()


@lru_cache(maxsize=1)
def _bundle_suivi():
    b = joblib.load(SUIVI_PATH)
    return {"modele": b["modele"], "seuil": float(b["seuil"]), "features": list(b["features"])}


@lru_cache(maxsize=1)
def _bundle_controle():
    b = joblib.load(CONTROLE_PATH)
    return {"modele": b["modele"], "seuil": float(b["seuil"]), "features": list(b["features"])}


def vers_features(f: dict) -> dict:
    """Fiche du formulaire -> features des modèles (valeurs anglaises inchangées)."""
    age = int(re.search(r"\d+", f["age"]).group()) // 10          # "[70-80]" -> 7
    return {
        "age": age,
        "time_in_hospital": f["hosp_days"],
        "num_medications": f["medications"],
        "number_diagnoses": f["diagnostics"],
        "diabetesMed_num": 1 if f["antidiabetic"] == "Oui" else 0,
        "insulin_prescrite": 0 if f["insulin"] in ("Non", "No") else 1,   # Up/Down/Oui -> 1
        "metformin_prescrite": 0 if f["metformin"] in ("Non", "No") else 1,
        "diag_1_group": f["diagnosis"],
        "max_glu_serum": f["glucose"],                                    # M1 seulement
    }


def predire_suivi(data: dict) -> dict:
    b = _bundle_suivi()
    X = pd.DataFrame([{f: data[f] for f in b["features"]}], columns=b["features"])
    proba = float(b["modele"].predict_proba(X)[0, 1])
    classe = int(proba >= b["seuil"])
    return {
        "proba": round(proba, 4), "pourcentage": round(proba * 100), "classe": classe,
        "seuil": round(b["seuil"], 4),
        "resultat": "Enhanced follow-up" if classe == 1 else "Light follow-up",
    }


def predire_controle(data: dict) -> dict:
    b = _bundle_controle()
    X = pd.DataFrame([{f: data[f] for f in b["features"]}], columns=b["features"])
    proba = float(b["modele"].predict_proba(X)[0, 1])
    classe = int(proba >= b["seuil"])
    return {
        "proba": round(proba, 4), "pourcentage": round(proba * 100), "classe": classe,
        "seuil": round(b["seuil"], 4),
        "resultat": "Poorly controlled" if classe == 1 else "Well controlled",
        "message": MESSAGES_CONTROLE_FR[classe],
    }


def predire(fiche: dict) -> dict:
    """Combine M1 + M2 en un profil de sortie."""
    feats = vers_features(fiche)
    suivi = predire_suivi(feats)       # 9 features (dont max_glu_serum)
    ctrl = predire_controle(feats)     # 8 features (ignore max_glu_serum)
    return {
        "suivi": {k: suivi[k] for k in ("proba", "pourcentage", "classe", "seuil", "resultat")},
        "controle": {k: ctrl[k] for k in
                     ("proba", "pourcentage", "classe", "seuil", "resultat", "message")},
        "profil": PROFILS[(suivi["classe"], ctrl["classe"])],
    }
