# -*- coding: utf-8 -*-
"""
Doza — prédiction du changement de dose d'insuline (logique métier).

Reproduit EXACTEMENT la spec (`Projet ML/api/predict.py` + `models/insulin_meta.json`) :
conversions code→catégorie, défauts, seuil 0.315, zones + taux réels, et l'analyse
de sensibilité « et si » (top-3 facteurs). Le pipeline calibré (Gradient Boosting) et
ses métadonnées sont chargés UNE SEULE FOIS depuis artifacts/doza/.

Population : patients déjà sous insuline. Cible : la dose va-t-elle changer
(Up/Down = 1) ou rester stable (Steady = 0) ?
"""
import json
from functools import lru_cache

import joblib
import pandas as pd

from app.core.config import ARTIFACTS_DIR

ARTIFACT_DIR = ARTIFACTS_DIR / "doza"

# ---------------------------------------------------------------------------
# CODE du questionnaire -> CATEGORIE du modèle. « Je ne sais pas »/« Autre »
# -> Unknown / Not_Tested / Other. (identique à api/predict.py)
# ---------------------------------------------------------------------------
CONVERSION = {
    "gender":              {1: "Male", 0: "Female"},
    "admission_type_id":   {1: "1", 2: "2", 3: "3", 0: "Unknown"},
    "admission_source_id": {7: "7", 1: "1", 6: "6", 0: "Other", "jnsp": "Unknown"},
    "A1Cresult":           {1: "Norm", 2: ">7", 3: ">8", 0: "Not_Tested"},
}

# Valeurs par défaut si une réponse manque.
DEFAUTS = {
    "age_ordinal": 6, "gender": "Female", "admission_type_id": "Unknown",
    "admission_source_id": "Unknown", "diag_1_group": "Other",
    "number_emergency": 0, "number_inpatient": 0, "number_outpatient": 0,
    "A1Cresult": "Not_Tested", "num_medications": 13,
    "medical_specialty": "Unknown", "sulfonylurea_bin": 0,
}

# Options possibles (valeurs MODELE) pour l'analyse « et si », + libellés FR.
OPTIONS = {
    "age_ordinal": [3, 4, 5, 6, 7, 8],
    "gender": ["Male", "Female"],
    "admission_type_id": ["1", "2", "3", "Unknown"],
    "admission_source_id": ["7", "1", "6", "Other", "Unknown"],
    "diag_1_group": ["Diabetes", "Circulatory", "Respiratory", "Digestive", "Genitourinary",
                     "Musculoskeletal", "Injury", "Neoplasms", "Other"],
    "number_emergency": [0, 1, 2, 3],
    "number_inpatient": [0, 1, 2, 3],
    "number_outpatient": [0, 2, 4, 6],
    "A1Cresult": ["Norm", ">7", ">8", "Not_Tested"],
    "num_medications": [3, 8, 13, 18, 25],
    "medical_specialty": ["InternalMedicine", "Emergency/Trauma", "Family/GeneralPractice",
                          "Cardiology", "Other", "Unknown"],
    "sulfonylurea_bin": [0, 1],
}
FIELD_FR = {
    "age_ordinal": "age", "gender": "sex", "admission_type_id": "admission type",
    "admission_source_id": "source", "diag_1_group": "reason for admission",
    "number_emergency": "ER visits", "number_inpatient": "inpatient stays",
    "number_outpatient": "outpatient visits", "A1Cresult": "HbA1c",
    "num_medications": "number of medications",
    "medical_specialty": "department", "sulfonylurea_bin": "sulfonylurea use",
}
VALUE_FR = {
    "age_ordinal": {3: "18–39", 4: "40–49", 5: "50–59", 6: "60–69", 7: "70–79", 8: "80+"},
    "gender": {"Male": "male", "Female": "female"},
    "admission_type_id": {"1": "emergency", "2": "urgent", "3": "elective", "Unknown": "unknown"},
    "admission_source_id": {"7": "ER", "1": "physician", "6": "transfer",
                            "Other": "other", "Unknown": "unknown"},
    "diag_1_group": {"Diabetes": "diabetes", "Circulatory": "heart/vessels", "Respiratory": "lungs",
                     "Digestive": "digestive", "Genitourinary": "kidneys",
                     "Musculoskeletal": "joints", "Injury": "injury",
                     "Neoplasms": "cancer", "Other": "other"},
    "number_emergency": {0: "0", 1: "1", 2: "2", 3: "3+"},
    "number_inpatient": {0: "0", 1: "1", 2: "2", 3: "3+"},
    "number_outpatient": {0: "0", 2: "1–2", 4: "3–5", 6: "6+"},
    "A1Cresult": {"Norm": "< 7 %", ">7": "7–8 %", ">8": "> 8 %", "Not_Tested": "unknown"},
    "num_medications": {3: "1–5", 8: "6–10", 13: "11–15", 18: "16–20", 25: "> 20"},
    "medical_specialty": {"InternalMedicine": "internal medicine", "Emergency/Trauma": "ER",
                          "Family/GeneralPractice": "family / GP", "Cardiology": "cardiology",
                          "Other": "other department", "Unknown": "unknown"},
    "sulfonylurea_bin": {0: "no", 1: "yes"},
}


@lru_cache(maxsize=1)
def _load():
    """Charge le pipeline calibré + les métadonnées UNE SEULE FOIS."""
    pipe = joblib.load(ARTIFACT_DIR / "insulin_pipeline.joblib")
    meta = json.loads((ARTIFACT_DIR / "insulin_meta.json").read_text(encoding="utf-8"))
    return pipe, meta


def features() -> list:
    return _load()[1]["features"]


def seuil() -> float:
    return _load()[1]["seuil"]


def zones() -> list:
    return _load()[1]["zones"]


def _vers_modele(patient: dict) -> dict:
    """Reponses du questionnaire -> ligne au format attendu par le modèle."""
    feats = features()
    row = dict(DEFAUTS)
    for key, val in patient.items():
        feat = "sulfonylurea_bin" if key == "sulfonylurea" else key
        if feat not in feats:
            continue
        if key in CONVERSION:
            row[feat] = CONVERSION[key].get(val, DEFAUTS[feat])
        else:
            row[feat] = val
    return {f: row.get(f, DEFAUTS[f]) for f in feats}


def _proba(row_modele: dict) -> float:
    pipe, meta = _load()
    X = pd.DataFrame([row_modele], columns=meta["features"])
    return float(pipe.predict_proba(X)[0, 1])


def _zone(p: float):
    """(nom, taux_reel_%) de la zone contenant p."""
    for z in zones():
        nom, lo, hi = z[0], z[1], z[2]
        taux = z[3] if len(z) > 3 else None
        if (lo <= p < hi) or (hi >= 1.0 and p >= lo):
            return nom, taux
    last = zones()[-1]
    return last[0], (last[3] if len(last) > 3 else None)


def _label(feat, val):
    return VALUE_FR.get(feat, {}).get(val, str(val))


def predire(patient: dict) -> dict:
    """proba, classe, seuil, zone, zone_taux et top-3 facteurs (explication, pas un conseil)."""
    base = _vers_modele(patient)
    p0 = _proba(base)
    s = seuil()
    classe = int(p0 >= s)

    # Analyse de sensibilité : de combien bougerait l'estimation si la réponse
    # était différente ? C'est une EXPLICATION (quels facteurs ont pesé), pas un
    # contrefactuel actionnable (l'âge, la provenance… ne sont pas modifiables).
    facteurs = []
    for feat in features():
        cur = base[feat]
        meilleur = 0.0
        for alt in OPTIONS.get(feat, []):
            if alt == cur:
                continue
            row = dict(base); row[feat] = alt
            meilleur = max(meilleur, abs(_proba(row) - p0))
        if meilleur > 0.005:
            facteurs.append({"champ": FIELD_FR[feat], "reponse": _label(feat, cur),
                             "impact": round(meilleur * 100)})
    facteurs.sort(key=lambda d: d["impact"], reverse=True)

    zone_nom, zone_taux = _zone(p0)
    return {
        "proba": round(p0, 4),
        "pourcentage": round(p0 * 100),
        "classe": classe,
        "seuil": s,
        "zone": zone_nom,
        "zone_taux": zone_taux,
        "facteurs": facteurs[:3],
    }
