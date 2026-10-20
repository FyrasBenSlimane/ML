"""Modèle 1 : risque de retour à l'hôpital en moins de 30 jours.

Code recopié tel quel de modele1_readmission_30j.ipynb (étapes 3, 5 et 11).
Les valeurs calculées sur les données d'entraînement (TOP_SPEC, CATEGORIES, seuils)
sont lues dans model_readmission_30d.joblib, où le notebook les a figées.
"""
from pathlib import Path

import joblib
import numpy as np
import pandas as pd

ARTIFACT_PATH = Path(__file__).resolve().parent / "model_readmission_30d.joblib"
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
       "n_meds_diabete","n_meds_modifies"]

TOP_SPEC = _A["top_spec"]

def build_features(d):
    """Transforme les colonnes brutes en variables du modèle (réutilisable pour un nouveau patient)."""
    d = d.copy()
    for c in ["diag_1","diag_2","diag_3"]:
        d[c + "_grp"] = d[c].map(icd9_group)
    d["age_num"] = d["age"].str.extract(r"\[(\d+)-")[0].astype(float) + 5
    d["n_meds_diabete"]  = (d[MED_COLS] != "No").sum(axis=1)
    d["n_meds_modifies"] = d[MED_COLS].isin(["Up", "Down"]).sum(axis=1)
    d["visites_anterieures"] = d["number_outpatient"] + d["number_emergency"] + d["number_inpatient"]
    d["specialite"] = d["medical_specialty"].where(d["medical_specialty"].isin(TOP_SPEC), "autre").fillna("inconnue")
    for c, v in [("payer_code","inconnu"),("race","inconnu"),("A1Cresult","non_mesure"),("max_glu_serum","non_mesure")]:
        d[c] = d[c].fillna(v)
    X = d[CAT + NUM].copy()
    for c in ["admission_type_id","admission_source_id","discharge_disposition_id"]:
        X[c] = X[c].astype(str)
    return X

CATEGORIES = _A["categories"]

def apply_categories(X):
    X = X.copy()
    for c in CAT:
        X[c] = pd.Categorical(X[c].astype(str), categories=CATEGORIES[c])
    return X

# ---- Étape 5 du notebook ----
def prep(name, Xd):
    """CatBoost veut des textes pour les variables catégorielles ; les autres gardent le type 'category'."""
    if name.startswith("CatBoost"):
        Xd = Xd.copy()
        for c in CAT: Xd[c] = Xd[c].astype(str)
    return Xd

# ---- Étape 11 du notebook ----
final_model = _A["model"]
iso = _A["calibrator"]
BEST_NAME = _A["best_name"]
thr_med = _A["thr_med"]
thr_high = _A["thr_high"]

def predict_patients(raw_df):
    """raw_df : tableau avec les MÊMES colonnes que diabetic_data.csv. Renvoie risque et niveau."""
    Xn = apply_categories(build_features(raw_df))
    p = iso.predict(final_model.predict_proba(prep(BEST_NAME, Xn))[:, 1])
    lvl = np.where(p >= thr_high, "élevé", np.where(p >= thr_med, "moyen", "faible"))
    return pd.DataFrame({"risque_retour_30j": p.round(3), "niveau": lvl}, index=raw_df.index)


if CAT != _A["cat"] or NUM != _A["num"]:
    raise RuntimeError("model_readmission_30d.joblib ne correspond pas aux variables du notebook (CAT/NUM).")
