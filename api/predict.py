# -*- coding: utf-8 -*-
"""
Prediction du changement de dose d'insuline — logique metier (sans serveur web).

- charge UNE SEULE FOIS le pipeline calibre (models/insulin_pipeline.joblib) ;
- `predire(patient: dict)` renvoie la probabilite, la classe, le seuil, la zone de
  risque, et une explication "et si" par patient (le Gradient Boosting n'a pas de
  chemin de decision, on teste donc les autres reponses possibles de chaque question).

Population : patients deja sous insuline. Cible : la dose va-t-elle changer
(Up/Down = 1) ou rester stable (Steady = 0) ?
"""
from pathlib import Path
import json
import joblib
import pandas as pd

# --- Chargement unique du modele et des metadonnees ---
ROOT = Path(__file__).resolve().parent.parent
_PIPE = joblib.load(ROOT / "models" / "insulin_pipeline.joblib")
_META = json.loads((ROOT / "models" / "insulin_meta.json").read_text(encoding="utf-8"))

FEATURES = _META["features"]          # ordre exact des 12 colonnes attendues par le modele
SEUIL = _META["seuil"]                # seuil de decision (0.315)
ZONES = _META["zones"]                # [[nom, min, max], ...]

# ---------------------------------------------------------------------------
# Dictionnaire de conversion : CODE du questionnaire -> CATEGORIE du modele.
# Le questionnaire (chat/index.php) envoie des codes ; le modele attend les
# categories vues a l'entrainement (apres regroupement). "Je ne sais pas"/"Autre"
# -> Unknown / Not_Tested / Other.
# ---------------------------------------------------------------------------
CONVERSION = {
    "gender":              {1: "Male", 0: "Female"},
    "admission_type_id":   {1: "1", 2: "2", 3: "3", 0: "Unknown"},          # 0 = Je ne sais pas
    "admission_source_id": {7: "7", 1: "1", 6: "6", 0: "Other", "jnsp": "Unknown"},  # Autre / Je ne sais pas
    "A1Cresult":           {1: "Norm", 2: ">7", 3: ">8", 0: "Not_Tested"},  # 0 = Je ne sais pas
    # medical_specialty et diag_1_group : le questionnaire envoie deja la categorie
    # du modele (InternalMedicine, Unknown, Other, Diabetes, ...). Identite.
    # num_medications : deja en tranche (3/8/13/18/25). age_ordinal / number_* : numeriques.
    # sulfonylurea (0/1) -> feature sulfonylurea_bin.
}

# Valeurs par defaut si une reponse manque (ex. question non posee).
DEFAUTS = {
    "age_ordinal": 6, "gender": "Female", "admission_type_id": "Unknown",
    "admission_source_id": "Unknown", "diag_1_group": "Other",
    "number_emergency": 0, "number_inpatient": 0, "number_outpatient": 0,
    "A1Cresult": "Not_Tested", "num_medications": 13,
    "medical_specialty": "Unknown", "sulfonylurea_bin": 0,
}

# Options possibles (en valeurs MODELE) pour l'analyse "et si", + libelles FR.
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
    "age_ordinal": "âge", "gender": "sexe", "admission_type_id": "type d'admission",
    "admission_source_id": "provenance", "diag_1_group": "motif d'hospitalisation",
    "number_emergency": "passages aux urgences", "number_inpatient": "hospitalisations",
    "number_outpatient": "consultations", "A1Cresult": "HbA1c", "num_medications": "nombre de médicaments",
    "medical_specialty": "service", "sulfonylurea_bin": "prise d'un sulfamide",
}
VALUE_FR = {
    "age_ordinal": {3: "18–39", 4: "40–49", 5: "50–59", 6: "60–69", 7: "70–79", 8: "80+"},
    "gender": {"Male": "homme", "Female": "femme"},
    "admission_type_id": {"1": "urgence", "2": "urgente", "3": "programmée", "Unknown": "inconnu"},
    "admission_source_id": {"7": "urgences", "1": "médecin", "6": "transfert", "Other": "autre", "Unknown": "inconnu"},
    "diag_1_group": {"Diabetes": "diabète", "Circulatory": "cœur/vaisseaux", "Respiratory": "poumons",
                     "Digestive": "digestif", "Genitourinary": "reins", "Musculoskeletal": "articulations",
                     "Injury": "blessure", "Neoplasms": "cancer", "Other": "autre"},
    "number_emergency": {0: "0", 1: "1", 2: "2", 3: "3+"},
    "number_inpatient": {0: "0", 1: "1", 2: "2", 3: "3+"},
    "number_outpatient": {0: "0", 2: "1–2", 4: "3–5", 6: "6+"},
    "A1Cresult": {"Norm": "< 7 %", ">7": "7–8 %", ">8": "> 8 %", "Not_Tested": "inconnue"},
    "num_medications": {3: "1–5", 8: "6–10", 13: "11–15", 18: "16–20", 25: "> 20"},
    "medical_specialty": {"InternalMedicine": "médecine interne", "Emergency/Trauma": "urgences",
                          "Family/GeneralPractice": "médecine générale", "Cardiology": "cardiologie",
                          "Other": "autre service", "Unknown": "inconnu"},
    "sulfonylurea_bin": {0: "non", 1: "oui"},
}


def _vers_modele(patient: dict) -> dict:
    """Convertit les reponses du questionnaire en une ligne au format attendu par le modele."""
    row = dict(DEFAUTS)
    for key, val in patient.items():
        feat = "sulfonylurea_bin" if key == "sulfonylurea" else key
        if feat not in FEATURES:
            continue
        if key in CONVERSION:
            row[feat] = CONVERSION[key].get(val, DEFAUTS[feat])
        else:
            row[feat] = val
    return {f: row.get(f, DEFAUTS[f]) for f in FEATURES}


def _proba(row_modele: dict) -> float:
    X = pd.DataFrame([row_modele], columns=FEATURES)
    return float(_PIPE.predict_proba(X)[0, 1])


def _zone(p: float):
    """Renvoie (nom, taux_reel_%) de la zone contenant p."""
    for z in ZONES:
        nom, lo, hi = z[0], z[1], z[2]
        taux = z[3] if len(z) > 3 else None
        if (lo <= p < hi) or (hi >= 1.0 and p >= lo):
            return nom, taux
    return ZONES[-1][0], (ZONES[-1][3] if len(ZONES[-1]) > 3 else None)


def _label(feat, val):
    return VALUE_FR.get(feat, {}).get(val, str(val))


def predire(patient: dict) -> dict:
    """Renvoie proba, classe, seuil, zone, explication 'et si' et ce qui changerait le resultat."""
    base = _vers_modele(patient)
    p0 = _proba(base)
    classe = int(p0 >= SEUIL)

    # Facteurs qui ont le plus pese pour CE patient : on mesure, variable par variable,
    # de combien l'estimation bougerait si la reponse etait differente (analyse de sensibilite).
    # On ne propose PAS de contrefactuel actionnable : certaines variables (age, provenance...)
    # ne sont pas modifiables par le patient. C'est une explication, pas un conseil.
    facteurs = []
    for feat in FEATURES:
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
        "seuil": SEUIL,
        "zone": zone_nom,
        "zone_taux": zone_taux,            # taux reel de changement observe dans cette zone (%)
        "facteurs": facteurs[:3],          # les facteurs qui ont le plus pese (explication, pas un conseil)
    }
