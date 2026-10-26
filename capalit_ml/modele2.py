"""Modèle 2 : durée du séjour de retour (si le patient revient).

Code recopié tel quel de modele2_duree_sejour_retour.ipynb (étapes 3, 8 et 11).
Les valeurs calculées sur les données d'entraînement (TOP_SPEC, CATEGORIES, DELTA)
sont lues dans model_duree_sejour_retour.joblib, où le notebook les a figées.
"""
from pathlib import Path

import joblib
import numpy as np
import pandas as pd

ARTIFACT_PATH = Path(__file__).resolve().parent / "model_duree_sejour_retour.joblib"
_A = joblib.load(ARTIFACT_PATH)

# ---- Étape 3 du notebook ----
MED_COLS = ["metformin","repaglinide","nateglinide","chlorpropamide","glimepiride","acetohexamide",
            "glipizide","glyburide","tolbutamide","pioglitazone","rosiglitazone","acarbose","miglitol",
            "troglitazone","tolazamide","examide","citoglipton","insulin","glyburide-metformin",
            "glipizide-metformin","glimepiride-pioglitazone","metformin-rosiglitazone","metformin-pioglitazone"]

def icd9_group(code):
    if pd.isna(code): return "inconnu"
    c = str(code)
    if c.startswith(("E", "V")): return "autre"
    n = float(c)
    if int(n) == 250: return "diabete"
    if 390 <= n <= 459 or int(n) == 785: return "circulatoire"
    if 460 <= n <= 519 or int(n) == 786: return "respiratoire"
    if 520 <= n <= 579 or int(n) == 787: return "digestif"
    if 800 <= n <= 999: return "blessure"
    if 710 <= n <= 739: return "musculo-squelettique"
    if 580 <= n <= 629 or int(n) == 788: return "genito-urinaire"
    if 140 <= n <= 239: return "cancer"
    return "autre"

CAT = ["race","gender","payer_code","specialite","diag_1_grp","diag_2_grp","diag_3_grp","A1Cresult",
       "max_glu_serum","insulin","metformin","change","diabetesMed","admission_type_id",
       "admission_source_id","discharge_disposition_id"]
NUM = ["age_num","number_outpatient","number_emergency","number_inpatient","visites_anterieures",
       "number_diagnoses","time_in_hospital","num_lab_procedures","num_procedures","num_medications",
       "n_meds_diabete","n_meds_modifies","retour_lt30"]

TOP_SPEC = _A["top_spec"]

def build_features(d, retour_lt30=None):
    """Variables du séjour qui se termine. retour_lt30 : None = lire is_lt30 ; sinon valeur imposée (1 à l'utilisation)."""
    d = d.copy()
    for c in ["diag_1", "diag_2", "diag_3"]:
        d[c + "_grp"] = d[c].map(icd9_group)
    d["age_num"] = d["age"].str.extract(r"\[(\d+)-")[0].astype(float) + 5
    d["n_meds_diabete"]  = (d[MED_COLS] != "No").sum(axis=1)
    d["n_meds_modifies"] = d[MED_COLS].isin(["Up", "Down"]).sum(axis=1)
    d["visites_anterieures"] = d["number_outpatient"] + d["number_emergency"] + d["number_inpatient"]
    d["specialite"] = d["medical_specialty"].where(d["medical_specialty"].isin(TOP_SPEC), "autre").fillna("inconnue")
    for c, v in [("payer_code","inconnu"),("race","inconnu"),("A1Cresult","non_mesure"),("max_glu_serum","non_mesure")]:
        d[c] = d[c].fillna(v)
    d["retour_lt30"] = d["is_lt30"] if retour_lt30 is None else retour_lt30
    X = d[CAT + NUM].copy()
    for c in ["admission_type_id", "admission_source_id", "discharge_disposition_id"]:
        X[c] = X[c].astype(str)
    return X

CATEGORIES = _A["categories"]

def apply_categories(X):
    X = X.copy()
    for c in CAT:
        X[c] = pd.Categorical(X[c].astype(str), categories=CATEGORIES[c])
    return X

# ---- Étape 8 du notebook ----
m_med = _A["m_med"]
m_q10 = _A["m_q10"]
m_q90 = _A["m_q90"]
m_avg = _A["m_avg"]
DELTA = _A["delta"]

def predict_all(Xd, widen=True):
    med = np.clip(m_med.predict(Xd), 1, 14)
    lo = np.clip(m_q10.predict(Xd), 1, 14)
    hi = np.clip(m_q90.predict(Xd), 1, 14)
    avg = np.clip(m_avg.predict(Xd), 1, 14)
    lo, hi = np.minimum(lo, med), np.maximum(hi, med)    # garantit bas <= médiane <= haut
    if widen:
        lo, hi = np.clip(lo - DELTA, 1, 14), np.clip(hi + DELTA, 1, 14)
    return med, lo, hi, avg

# ---- Étape 11 du notebook ----
def predict_los(raw_df):
    """raw_df : séjours (mêmes colonnes que diabetic_data.csv). Renvoie la durée du séjour de retour, SI le patient revient."""
    d = raw_df.copy()
    d["is_lt30"] = 1
    Xn = apply_categories(build_features(d, retour_lt30=1))
    med, lo, hi, avg = predict_all(Xn)
    return pd.DataFrame({"duree_mediane_j": med.round(1), "duree_basse_j": lo.round(1),
                         "duree_haute_j": hi.round(1), "duree_moyenne_j": avg.round(1)}, index=raw_df.index)

def charge_attendue(p_retour, los_moyenne):
    """Jours-lits attendus pour un patient = probabilité de retour x durée moyenne prévue."""
    return np.asarray(p_retour) * np.asarray(los_moyenne)


if CAT != _A["cat"] or NUM != _A["num"]:
    raise RuntimeError("model_duree_sejour_retour.joblib ne correspond pas aux variables du notebook (CAT/NUM).")
